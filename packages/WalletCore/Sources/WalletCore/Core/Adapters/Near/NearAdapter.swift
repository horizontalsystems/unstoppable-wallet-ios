import BigInt
import Combine
import Foundation
import NearKit
import RxSwift

class NearAdapter {
    static let decimals = NearAmount.decimals
    // Android DEFAULT_FEE: a transfer to a named account at the usual gas price, shown until an estimate arrives
    static let defaultFee = Decimal(string: "0.0000446")!

    let nearKit: NearKit.Kit
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

    init(nearKit: NearKit.Kit) {
        self.nearKit = nearKit

        balanceState = Self.adapterState(kitSyncState: nearKit.syncState)
        balanceData = Self.balanceData(accountState: nearKit.accountState)

        nearKit.syncStatePublisher
            .sink { [weak self] in self?.balanceState = Self.adapterState(kitSyncState: $0) }
            .store(in: &cancellables)

        nearKit.accountStatePublisher
            .sink { [weak self] in self?.balanceData = Self.balanceData(accountState: $0) }
            .store(in: &cancellables)
    }

    private static func balanceData(accountState: AccountState) -> BalanceData {
        BalanceData(total: near(yocto: accountState.amount), available: near(yocto: accountState.available))
    }

    static func near(yocto: BigUInt) -> Decimal {
        Decimal(bigUInt: yocto, decimals: decimals) ?? 0
    }

    static func adapterState(kitSyncState: NearKit.SyncState) -> AdapterState {
        switch kitSyncState {
        case .syncing: return .syncing(progress: nil, remaining: nil, lastBlockDate: nil)
        case .synced: return .synced
        case let .notSynced(error):
            if let syncError = error as? NearKit.SyncError, case .notStarted = syncError {
                return .syncing(progress: nil, remaining: nil, lastBlockDate: nil)
            }
            return .notSynced(error: error.localizedDescription)
        }
    }

    static func clear(except excludedWalletIds: [String]) throws {
        try NearKit.Kit.clear(exceptFor: excludedWalletIds)
    }
}

extension NearAdapter: IBaseAdapter {
    var isMainNet: Bool {
        nearKit.network.isMainNet
    }
}

extension NearAdapter: IAdapter {
    func start() {}

    func stop() {}

    func refresh() {
        nearKit.refresh()
    }

    var statusInfo: [(String, Any)] {
        nearKit.statusInfo()
    }

    var debugInfo: String {
        ""
    }
}

extension NearAdapter: IBalanceAdapter {
    var balanceStateUpdatedObservable: Observable<AdapterState> {
        balanceStateSubject.asObservable()
    }

    var balanceDataUpdatedObservable: Observable<BalanceData> {
        balanceDataSubject.asObservable()
    }
}

extension NearAdapter: ISendNearAdapter {
    var address: String {
        nearKit.accountId
    }

    var availableNear: Decimal {
        Self.near(yocto: nearKit.availableBalance)
    }

    var pendingTransactionHashes: Set<String> {
        Set(((try? nearKit.pendingTransactions()) ?? []).map(\.hash))
    }

    func doesAccountExist(address: String) async throws -> Bool {
        try await nearKit.doesAccountExist(accountId: address)
    }

    func estimate(address: String, amount: Decimal, memo _: String?) async throws -> NearSendEstimate {
        let estimate = try await nearKit.estimateNearTransfer(receiverId: address)
        let fee = Self.near(yocto: estimate.fee)
        self.fee = fee

        return NearSendEstimate(
            fee: fee,
            storageDeposit: nil,
            requiredNear: Self.near(yocto: estimate.requiredBalance) + amount,
            ftTransferEstimate: nil
        )
    }

    func send(amount: Decimal, address: String, memo _: String?, estimate _: NearSendEstimate, signer: NearKit.Signer) async throws -> String {
        guard let yocto = BigUInt(amount.hs.roundedString(decimal: Self.decimals)) else {
            throw NearKit.SendError.invalidAmount
        }

        return try await nearKit.sendNear(receiverId: address, amount: yocto, signer: signer).hash
    }
}

extension NearAdapter: IDepositAdapter {
    var receiveAddress: DepositAddress {
        DepositAddress(nearKit.receiveAddress)
    }
}
