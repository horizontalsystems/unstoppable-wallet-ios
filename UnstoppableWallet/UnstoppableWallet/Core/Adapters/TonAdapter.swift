import BigInt
import Combine
import Foundation
import RxSwift
import TonKit
import TonSwift

class TonAdapter {
    private static let decimals = 9

    private let tonKit: TonKit.Kit
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

    private let transactionRecordsSubject = PublishSubject<[TonTransactionRecord]>()

    init(tonKit: TonKit.Kit) {
        self.tonKit = tonKit

        balanceState = Self.adapterState(kitSyncState: tonKit.syncState)
        balanceData = BalanceData(available: Self.amount(kitAmount: tonKit.account?.balance))

        tonKit.syncStatePublisher
            .sink { [weak self] in self?.balanceState = Self.adapterState(kitSyncState: $0) }
            .store(in: &cancellables)

        tonKit.accountPublisher
            .sink { [weak self] in self?.balanceData = BalanceData(available: Self.amount(kitAmount: $0?.balance)) }
            .store(in: &cancellables)
    }

    private static func adapterState(kitSyncState: TonKit.SyncState) -> AdapterState {
        switch kitSyncState {
        case .syncing: return .syncing(progress: nil, lastBlockDate: nil)
        case .synced: return .synced
        case let .notSynced(error): return .notSynced(error: error)
        }
    }

    private static func amount(kitAmount: BigUInt?) -> Decimal {
        guard let kitAmount, let significand = Decimal(string: kitAmount.description) else {
            return 0
        }

        return Decimal(sign: .plus, exponent: -Self.decimals, significand: significand)
    }

    static func amount(kitAmount: String) -> Decimal {
        amount(kitAmount: BigUInt(kitAmount))
    }

    static func amount(kitAmount: Int64) -> Decimal {
        amount(kitAmount: BigUInt(kitAmount))
    }
}

extension TonAdapter: IBaseAdapter {
    var isMainNet: Bool {
        true
    }
}

extension TonAdapter: IAdapter {
    func start() {
        // started via TonKitManager
    }

    func stop() {
        // stopped via TonKitManager
    }

    func refresh() {
        // refreshed via TonKitManager
    }

    var statusInfo: [(String, Any)] {
        []
    }

    var debugInfo: String {
        ""
    }
}

extension TonAdapter: IBalanceAdapter {
    var balanceStateUpdatedObservable: Observable<AdapterState> {
        balanceStateSubject.asObservable()
    }

    var balanceDataUpdatedObservable: Observable<BalanceData> {
        balanceDataSubject.asObservable()
    }
}

extension TonAdapter: IDepositAdapter {
    var receiveAddress: DepositAddress {
        DepositAddress(tonKit.receiveAddress.toString(bounceable: false))
    }
}

extension TonAdapter: ISendTonAdapter {
    var availableBalance: Decimal {
        balanceData.available
    }

    func validate(address: String) throws {
        _ = try FriendlyAddress(string: address)
    }

    func estimateFee(recipient: String, amount: Decimal, comment: String?) async throws -> Decimal {
        let recipient = try FriendlyAddress(string: recipient)
        let amount = Decimal(sign: .plus, exponent: Self.decimals, significand: amount).rounded(decimal: 0)

        guard let kitAmount = BigUInt(amount.description) else {
            throw AmountError.invalidAmount
        }

        let kitFee = try await tonKit.estimateFee(recipient: recipient, amount: .amount(value: kitAmount), comment: comment)

        return Self.amount(kitAmount: kitFee)
    }

    func send(recipient: String, amount: Decimal, comment: String?) async throws {
        let recipient = try FriendlyAddress(string: recipient)
        let amount = Decimal(sign: .plus, exponent: Self.decimals, significand: amount).rounded(decimal: 0)

        guard let kitAmount = BigUInt(amount.description) else {
            throw AmountError.invalidAmount
        }

        try await tonKit.send(recipient: recipient, amount: .amount(value: kitAmount), comment: comment)
    }
}

extension TonAdapter {
    enum AmountError: Error {
        case invalidAmount
    }
}
