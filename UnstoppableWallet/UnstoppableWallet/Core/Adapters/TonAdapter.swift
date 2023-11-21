import Combine
import Foundation
import HdWalletKit
import MarketKit
import RxSwift
import TonKitKmm

class TonAdapter {
    static let coinRate: Decimal = 1_000_000_000

    private let tonKit: TonKit
    private let ownAddress: String
    private let transactionSource: TransactionSource
    private let baseToken: Token
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

    private let transactionsStateSubject = PublishSubject<AdapterState>()
    private(set) var transactionsState: AdapterState {
        didSet {
            transactionsStateSubject.onNext(transactionsState)
        }
    }

    init(wallet: Wallet, baseToken: Token) throws {
        transactionSource = wallet.transactionSource
        self.baseToken = baseToken

        guard let seed = wallet.account.type.mnemonicSeed else {
            throw AdapterError.unsupportedAccount
        }

        let hdWallet = HDWallet(seed: seed, coinType: 607, xPrivKey: 0, curve: .ed25519)
        let privateKey = try hdWallet.privateKey(account: 0)

        tonKit = TonKitFactory(driverFactory: DriverFactory()).create(seed: privateKey.raw.toKotlinByteArray())
        ownAddress = tonKit.receiveAddress

        balanceState = Self.adapterState(kitSyncState: tonKit.balanceSyncState)
        balanceData = Self.balanceData(kitBalance: tonKit.balance)
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
                self?.balanceData = Self.balanceData(kitBalance: balance)
            }
            .store(in: &cancellables)

        collect(tonKit.transactionsSyncStatePublisher)
            .completeOnFailure()
            .sink { [weak self] syncState in
                self?.transactionsState = Self.adapterState(kitSyncState: syncState)
            }
            .store(in: &cancellables)
    }

    private static func adapterState(kitSyncState: AnyObject) -> AdapterState {
        switch kitSyncState {
        case is TonKitKmm.SyncState.Syncing: return .syncing(progress: nil, lastBlockDate: nil)
        case is TonKitKmm.SyncState.Synced: return .synced
        case let notSyncedState as TonKitKmm.SyncState.NotSynced:
            print(notSyncedState.error)
            return .notSynced(error: notSyncedState.error)
        default: return .notSynced(error: AppError.unknownError)
        }
    }

    private static func balanceData(kitBalance: String?) -> BalanceData {
        guard let kitBalance, let decimal = Decimal(string: kitBalance) else {
            return BalanceData(available: 0)
        }

        return BalanceData(available: decimal / coinRate)
    }

    private func transactionRecord(tonTransaction tx: TonTransaction) -> TransactionRecord {
        switch tx.type {
        case "Incoming":
            return TonIncomingTransactionRecord(
                source: transactionSource,
                transaction: tx,
                feeToken: baseToken,
                token: baseToken
            )
        case "Outgoing":
            return TonOutgoingTransactionRecord(
                source: transactionSource,
                transaction: tx,
                feeToken: baseToken,
                token: baseToken,
                sentToSelf: ownAddress == tx.dest
            )
        default:
            return TonTransactionRecord(
                source: transactionSource,
                transaction: tx,
                feeToken: baseToken
            )
        }
    }
}

extension TonAdapter: IBaseAdapter {
    var isMainNet: Bool {
        true
    }
}

extension TonAdapter: IAdapter {
    func start() {
        tonKit.start()
    }

    func stop() {
        tonKit.stop()
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

    func explorerUrl(transactionHash: String) -> String? {
        "https://tonscan.org/tx/\(transactionHash)"
    }

    func transactionsObservable(token _: Token?, filter _: TransactionTypeFilter) -> Observable<[TransactionRecord]> {
        Observable.empty()
    }

    func transactionsSingle(from: TransactionRecord?, token _: Token?, filter _: TransactionTypeFilter, limit: Int) -> Single<[TransactionRecord]> {
        let single: Single<[TonTransaction]> = Single.create { [tonKit] observer in
            let task = Task { [tonKit] in
                do {
                    let tonTransactions = try await tonKit.transactions(fromTransactionHash: from?.transactionHash, type: nil, limit: Int64(limit))
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

    func rawTransaction(hash _: String) -> String? {
        nil
    }
}
