import Combine
import Foundation
import HdWalletKit
import HsToolKit
import MarketKit
import RxSwift
import TonKitKmm

class TonAdapter {
    private static let coinRate: Decimal = 1_000_000_000

    private let tonKit: TonKit
    private let ownAddress: String
    private let transactionSource: TransactionSource
    private let baseToken: Token
    private let reachabilityManager = App.shared.reachabilityManager
    private var cancellables = Set<AnyCancellable>()

    private var adapterStarted = false
    private var kitStarted = false

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

    private let transactionsStateSubject = PublishSubject<AdapterState>()
    private(set) var transactionsState: AdapterState {
        didSet {
            transactionsStateSubject.onNext(transactionsState)
        }
    }

    private let transactionRecordsSubject = PublishSubject<[TonTransactionRecord]>()

    init(wallet: Wallet, baseToken: Token) throws {
        transactionSource = wallet.transactionSource
        self.baseToken = baseToken

        switch wallet.account.type {
        case .mnemonic:
            guard let seed = wallet.account.type.mnemonicSeed else {
                throw AdapterError.unsupportedAccount
            }

            let hdWallet = HDWallet(seed: seed, coinType: 607, xPrivKey: 0, curve: .ed25519)
            let privateKey = try hdWallet.privateKey(account: 0)

            tonKit = TonKitFactory(driverFactory: DriverFactory(), connectionManager: ConnectionManager()).create(seed: privateKey.raw.toKotlinByteArray(), walletId: wallet.account.id)
        case let .tonAddress(address):
            tonKit = TonKitFactory(driverFactory: DriverFactory(), connectionManager: ConnectionManager()).createWatch(address: address, walletId: wallet.account.id)
        default:
            throw AdapterError.unsupportedAccount
        }

        ownAddress = tonKit.receiveAddress

        balanceState = Self.adapterState(kitSyncState: tonKit.balanceSyncState)
        balanceData = BalanceData(available: Self.amount(kitAmount: tonKit.balance))
        transactionsState = Self.adapterState(kitSyncState: tonKit.transactionsSyncState)

        collect(tonKit.balanceSyncStatePublisher)
            .completeOnFailure()
            .sink { [weak self] syncState in
                self?.balanceState = Self.adapterState(kitSyncState: syncState)
            }
            .store(in: &cancellables)

        collect(tonKit.balancePublisher)
            .completeOnFailure()
            .sink { [weak self] balance in
                self?.balanceData = BalanceData(available: Self.amount(kitAmount: balance))
            }
            .store(in: &cancellables)

        collect(tonKit.transactionsSyncStatePublisher)
            .completeOnFailure()
            .sink { [weak self] syncState in
                self?.transactionsState = Self.adapterState(kitSyncState: syncState)
            }
            .store(in: &cancellables)

        collect(tonKit.doNewTransactionsPublisher)
            .completeOnFailure()
            .sink { [weak self] tonTransactions in
                self?.handle(tonTransactions: tonTransactions)
            }
            .store(in: &cancellables)

        reachabilityManager.$isReachable
            .sink { [weak self] isReachable in
                self?.handle(isReachable: isReachable)
            }
            .store(in: &cancellables)
    }

    private func handle(isReachable: Bool) {
        guard adapterStarted else {
            return
        }

        if isReachable, !kitStarted {
            startKit()
        } else if !isReachable, kitStarted {
            stopKit()
        }
    }

    private func handle(tonTransactions: [TonTransaction]) {
        let transactionRecords = tonTransactions.map { transactionRecord(tonTransaction: $0) }
        transactionRecordsSubject.onNext(transactionRecords)
    }

    private static func adapterState(kitSyncState: AnyObject) -> AdapterState {
        switch kitSyncState {
        case is TonKitKmm.SyncState.Syncing: return .syncing(progress: nil, lastBlockDate: nil)
        case is TonKitKmm.SyncState.Synced: return .synced
        case let notSyncedState as TonKitKmm.SyncState.NotSynced: return .notSynced(error: notSyncedState.error)
        default: return .notSynced(error: AppError.unknownError)
        }
    }

    static func amount(kitAmount: String) -> Decimal {
        guard let decimal = Decimal(string: kitAmount) else {
            return 0
        }

        return decimal / coinRate
    }

    private func transactionRecord(tonTransaction tx: TonTransaction) -> TonTransactionRecord {
        switch tx.type {
        case TransactionType.incoming:
            return TonIncomingTransactionRecord(
                source: transactionSource,
                transaction: tx,
                feeToken: baseToken,
                token: baseToken
            )
        case TransactionType.outgoing:
            return TonOutgoingTransactionRecord(
                source: transactionSource,
                transaction: tx,
                feeToken: baseToken,
                token: baseToken
            )
        default:
            return TonTransactionRecord(
                source: transactionSource,
                transaction: tx,
                feeToken: baseToken
            )
        }
    }

    private func transactionsSingle(from: TransactionRecord?, type: TransactionType?, limit: Int) -> Single<[TransactionRecord]> {
        let single: Single<[TonTransaction]> = Single.create { [tonKit] observer in
            let task = Task { [tonKit] in
                do {
                    let tonTransactions = try await tonKit.transactions(fromTransactionHash: from?.transactionHash, type: type, limit: Int64(limit))
                    observer(.success(tonTransactions))
                } catch {
                    observer(.error(error))
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }

        return single.map { [weak self] tonTransactions -> [TransactionRecord] in
            tonTransactions.compactMap { self?.transactionRecord(tonTransaction: $0) }
        }
    }

    private func startKit() {
        tonKit.start()
        kitStarted = true
    }

    private func stopKit() {
        tonKit.stop()
        kitStarted = false
    }
}

extension TonAdapter: IBaseAdapter {
    var isMainNet: Bool {
        true
    }
}

extension TonAdapter: IAdapter {
    func start() {
        adapterStarted = true

        if reachabilityManager.isReachable {
            startKit()
        }
    }

    func stop() {
        adapterStarted = false

        if kitStarted {
            stopKit()
        }
    }

    func refresh() {}

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
        DepositAddress(tonKit.receiveAddress)
    }
}

extension TonAdapter: ITransactionsAdapter {
    var syncing: Bool {
        transactionsState.syncing
    }

    var syncingObservable: Observable<Void> {
        transactionsStateSubject.map { _ in () }
    }

    var lastBlockInfo: LastBlockInfo? {
        nil
    }

    var lastBlockUpdatedObservable: Observable<Void> {
        Observable.empty()
    }

    var explorerTitle: String {
        "tonscan.org"
    }

    var additionalTokenQueries: [TokenQuery] {
        []
    }

    func explorerUrl(transactionHash: String) -> String? {
        "https://tonscan.org/tx/\(transactionHash)"
    }

    func transactionsObservable(token _: Token?, filter: TransactionTypeFilter, address _: String?) -> Observable<[TransactionRecord]> {
        transactionRecordsSubject
            .map { transactionRecords in
                transactionRecords.compactMap { transaction -> TransactionRecord? in
                    switch (transaction, filter) {
                    case (_, .all): return transaction
                    case (is TonIncomingTransactionRecord, .incoming): return transaction
                    case (is TonOutgoingTransactionRecord, .outgoing): return transaction
                    default: return nil
                    }
                }
            }
            .filter { !$0.isEmpty }
    }

    func transactionsSingle(from: TransactionRecord?, token _: Token?, filter: TransactionTypeFilter, address _: String?, limit: Int) -> Single<[TransactionRecord]> {
        switch filter {
        case .all: return transactionsSingle(from: from, type: nil, limit: limit)
        case .incoming: return transactionsSingle(from: from, type: TransactionType.incoming, limit: limit)
        case .outgoing: return transactionsSingle(from: from, type: TransactionType.outgoing, limit: limit)
        default: return Single.just([])
        }
    }

    func rawTransaction(hash _: String) -> String? {
        nil
    }
}

extension TonAdapter: ISendTonAdapter {
    var availableBalance: Decimal {
        balanceData.available
    }

    func validate(address: String) throws {
        try TonKit.companion.validate(address: address)
    }

    func estimateFee() async throws -> Decimal {
        let kitAmount = try await tonKit.estimateFee()
        return Self.amount(kitAmount: kitAmount)
    }

    func send(recipient: String, amount: Decimal, memo: String?) async throws {
        let rawAmount = amount * Self.coinRate
        try await tonKit.send(recipient: recipient, amount: rawAmount.description, memo: memo)
    }
}
