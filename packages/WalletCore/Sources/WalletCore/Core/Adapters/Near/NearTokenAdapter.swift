import BigInt
import Combine
import Foundation
import MarketKit
import NearKit
import RxSwift

class NearTokenAdapter {
    let nearKit: NearKit.Kit
    let token: Token
    let contractId: String
    private let nearKitManager: NearKitManager
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

    private(set) var fee: Decimal = NearAdapter.defaultFee

    init(nearKit: NearKit.Kit, nearKitManager: NearKitManager, token: Token, contractId: String) {
        self.nearKit = nearKit
        self.nearKitManager = nearKitManager
        self.token = token
        self.contractId = contractId

        balanceState = NearAdapter.adapterState(kitSyncState: nearKit.syncState)
        balanceData = Self.balanceData(balance: nearKit.ftBalance(contractId: contractId), decimals: token.decimals)

        nearKit.syncStatePublisher
            .sink { [weak self] in self?.balanceState = NearAdapter.adapterState(kitSyncState: $0) }
            .store(in: &cancellables)

        nearKit.ftBalancePublisher(contractId: contractId)
            .sink { [weak self] balance in
                guard let self else { return }
                balanceData = Self.balanceData(balance: balance, decimals: self.token.decimals)
            }
            .store(in: &cancellables)
    }

    private static func balanceData(balance: BigUInt?, decimals: Int) -> BalanceData {
        BalanceData(balance: balance.flatMap { Decimal(bigUInt: $0, decimals: decimals) } ?? 0)
    }
}

extension NearTokenAdapter: IBaseAdapter {
    var isMainNet: Bool {
        nearKit.network.isMainNet
    }
}

extension NearTokenAdapter: IAdapter {
    func start() {
        nearKitManager.watch(contractId: contractId, nearKit: nearKit)
    }

    func stop() {
        nearKitManager.unwatch(contractId: contractId, nearKit: nearKit)
    }

    func refresh() {
        nearKit.refresh()
    }

    var statusInfo: [(String, Any)] {
        [
            ("Contract", contractId),
            ("Balance", nearKit.ftBalance(contractId: contractId)?.description ?? "none"),
        ]
    }

    var debugInfo: String {
        ""
    }
}

extension NearTokenAdapter: IBalanceAdapter {
    var balanceStateUpdatedObservable: Observable<AdapterState> {
        balanceStateSubject.asObservable()
    }

    var balanceDataUpdatedObservable: Observable<BalanceData> {
        balanceDataSubject.asObservable()
    }
}

extension NearTokenAdapter: ISendNearAdapter {
    var address: String {
        nearKit.accountId
    }

    var availableNear: Decimal {
        NearAdapter.near(yocto: nearKit.availableBalance)
    }

    var pendingTransactionHashes: Set<String> {
        Set(((try? nearKit.pendingTransactions()) ?? []).map(\.hash))
    }

    func estimate(address: String, amount: Decimal, memo: String?) async throws -> NearSendEstimate {
        let estimate = try await nearKit.estimateFtTransfer(contractId: contractId, receiverId: address, amount: units(amount: amount), memo: memo)
        let fee = NearAdapter.near(yocto: estimate.fee.fee)
        let storageDeposit = estimate.storageDeposit.map { NearAdapter.near(yocto: $0) }
        self.fee = fee

        return NearSendEstimate(
            fee: fee,
            storageDeposit: storageDeposit,
            // the one yoctoNEAR a token transfer attaches is below display precision
            requiredNear: NearAdapter.near(yocto: estimate.fee.requiredBalance) + (storageDeposit ?? 0),
            ftTransferEstimate: estimate
        )
    }

    /// Without the confirmed estimate the kit could not tell a changed storage deposit from the one
    /// the user saw, so a send without it is refused (Android `require(estimate is FtSendEstimate)`)
    func send(amount: Decimal, address: String, memo: String?, estimate: NearSendEstimate, signer: NearKit.Signer) async throws -> String {
        guard let ftTransferEstimate = estimate.ftTransferEstimate else {
            throw SendError.notTokenTransferEstimate
        }

        return try await nearKit.sendFt(
            contractId: contractId,
            receiverId: address,
            amount: units(amount: amount),
            memo: memo,
            estimate: ftTransferEstimate,
            signer: signer
        ).hash
    }

    private func units(amount: Decimal) throws -> BigUInt {
        guard let units = BigUInt(amount.hs.roundedString(decimal: token.decimals)) else {
            throw NearKit.SendError.invalidAmount
        }
        return units
    }
}

extension NearTokenAdapter {
    enum SendError: Error {
        case notTokenTransferEstimate
    }
}

extension NearTokenAdapter: IDepositAdapter {
    var receiveAddress: DepositAddress {
        DepositAddress(nearKit.receiveAddress)
    }
}
