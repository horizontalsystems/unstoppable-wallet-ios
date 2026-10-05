import Combine
import Foundation
import MarketKit
import RxSwift
import XrpKit

/// An issued currency held on a trust line. The balance is spendable only while the issuer has
/// not frozen the line; a missing line means the token is not activated yet.
class XrpTokenAdapter {
    let xrpKit: XrpKit.Kit
    let token: Token
    let currency: String
    let issuer: String
    private var cancellables = Set<AnyCancellable>()

    private let balanceStateSubject = PublishSubject<AdapterState>()
    private(set) var balanceState: AdapterState {
        didSet {
            balanceStateSubject.onNext(balanceState)
        }
    }

    private let balanceDataSubject = PublishSubject<BalanceData>()
    private(set) var balanceData: BalanceData {
        didSet {
            balanceDataSubject.onNext(balanceData)
        }
    }

    private let receiveAddressSubject = PassthroughSubject<DataStatus<DepositAddress>, Never>()

    private(set) var fee: Decimal = XrpAdapter.defaultFee
    private var feeTask: Task<Void, Never>?

    init(xrpKit: XrpKit.Kit, token: Token, currency: String, issuer: String) {
        self.xrpKit = xrpKit
        self.token = token
        self.currency = currency
        self.issuer = issuer

        balanceState = XrpAdapter.adapterState(kitSyncState: xrpKit.syncState)
        balanceData = Self.balanceData(trustLine: Self.trustLine(xrpKit: xrpKit, currency: currency, issuer: issuer))

        feeTask = Task { [weak self, xrpKit] in
            if let fee = try? await xrpKit.estimateFee() {
                self?.fee = fee
            }
        }

        xrpKit.syncStatePublisher
            .sink { [weak self] in self?.balanceState = XrpAdapter.adapterState(kitSyncState: $0) }
            .store(in: &cancellables)

        xrpKit.trustLinesPublisher
            .sink { [weak self] lines in
                guard let self else { return }
                balanceData = Self.balanceData(trustLine: lines.first { $0.currency == currency && $0.issuer == issuer })
                receiveAddressSubject.send(.completed(receiveAddress))
            }
            .store(in: &cancellables)
    }

    private static func trustLine(xrpKit: XrpKit.Kit, currency: String, issuer: String) -> TrustLine? {
        xrpKit.trustLines.first { $0.currency == currency && $0.issuer == issuer }
    }

    private static func balanceData(trustLine: TrustLine?) -> BalanceData {
        guard let trustLine else {
            return BalanceData(balance: 0)
        }
        // frozen by the issuer: the balance shows but cannot be sent (Android XrpTokenAdapter)
        return BalanceData(total: trustLine.balance, available: trustLine.frozen ? 0 : trustLine.balance)
    }

    var trustLine: TrustLine? {
        Self.trustLine(xrpKit: xrpKit, currency: currency, issuer: issuer)
    }

    var activated: Bool {
        trustLine != nil
    }
}

extension XrpTokenAdapter: IBaseAdapter {
    var isMainNet: Bool {
        xrpKit.network.isMainNet
    }
}

extension XrpTokenAdapter: IAdapter {
    func start() {
        // started via XrpKitManager
    }

    func stop() {
        // stopped via XrpKitManager
    }

    func refresh() {
        xrpKit.refresh()
    }

    var statusInfo: [(String, Any)] {
        [
            ("Currency", currency),
            ("Issuer", issuer),
            ("Trust Line", trustLine.map { "balance \($0.balance) limit \($0.limit) frozen \($0.frozen)" } ?? "none"),
        ]
    }

    var debugInfo: String {
        ""
    }
}

extension XrpTokenAdapter: IBalanceAdapter {
    var balanceStateUpdatedObservable: Observable<AdapterState> {
        balanceStateSubject.asObservable()
    }

    var balanceDataUpdatedObservable: Observable<BalanceData> {
        balanceDataSubject.asObservable()
    }
}

extension XrpTokenAdapter: ISendXrpAdapter {
    var address: String {
        xrpKit.address
    }

    var baseReserve: Decimal {
        xrpKit.baseReserve
    }

    var ownerReserve: Decimal {
        xrpKit.ownerReserve
    }

    var availableXrpBalance: Decimal {
        xrpKit.availableBalance
    }

    func doesAccountExist(address: String) async throws -> Bool {
        try await xrpKit.doesAccountExist(address: address)
    }

    func requiresDestinationTag(address: String) async throws -> Bool {
        try await xrpKit.requiresDestinationTag(address: address)
    }

    // an issued token is rejected by the ledger unless the recipient holds a trust line for it
    func canReceive(address: String) async throws -> Bool {
        try await xrpKit.isTrustLineSet(currency: currency, issuer: issuer, address: address)
    }

    func send(amount: Decimal, address: String, destinationTag: UInt32?, signer: XrpKit.Signer) async throws -> String {
        try await xrpKit.sendToken(currency: currency, issuer: issuer, to: address, amount: amount, destinationTag: destinationTag, signer: signer).hash
    }

    func setTrustLine(currency: String, issuer: String, limit: Decimal, signer: XrpKit.Signer) async throws -> String {
        try await xrpKit.setTrustLine(currency: currency, issuer: issuer, limit: limit, signer: signer).hash
    }
}

extension XrpTokenAdapter: IDepositAdapter {
    var receiveAddress: DepositAddress {
        XrpDepositAddress(
            receiveAddress: xrpKit.address,
            activated: activated,
            activationSendData: activated ? nil : .xrp(token: token, data: .trustSet(currency: currency, issuer: issuer, limit: XrpKit.Kit.defaultTrustLimit), destinationTag: nil)
        )
    }

    var receiveAddressPublisher: AnyPublisher<DataStatus<DepositAddress>, Never> {
        receiveAddressSubject.eraseToAnyPublisher()
    }
}
