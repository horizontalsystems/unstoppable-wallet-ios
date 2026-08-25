import Foundation
import HsExtensions
import HsToolKit
import RxSwift
import ZcashLightClientKit

class ZcashHistoryService {
    private let synchronizer: Synchronizer
    private let queue: DispatchQueue
    private let logger: HsToolKit.Logger?

    private let transactionSubject = PublishSubject<[ZcashTransactionWrapper]>()

    private(set) var transactionPool: ZcashTransactionPool?
    var lastBlockHeight: Int = 0

    // queue-confined tail of the serialized operation chain
    private var chainedTask: Task<Void, Never>?

    init(synchronizer: Synchronizer, queue: DispatchQueue, logger: HsToolKit.Logger?) {
        self.synchronizer = synchronizer
        self.queue = queue
        self.logger = logger
    }

    var transactionsObservable: Observable<[ZcashTransactionWrapper]> {
        transactionSubject.asObservable()
    }

    // Serializes pool work: every operation starts only after the previous one has finished,
    // so events are processed and published in arrival order without concurrent pool mutation.
    private func enqueue(_ operation: @escaping () async -> Void) {
        queue.async { [weak self] in
            guard let self else { return }
            chainedTask = Task { [previous = chainedTask] in
                await previous?.value
                await operation()
            }
        }
    }

    func initialize(transactionPool: ZcashTransactionPool) async {
        self.transactionPool = transactionPool

        logger?.log(level: .debug, message: "Starting fetch transactions.")
        await transactionPool.initTransactions()
        let wrapped = transactionPool.all

        if !wrapped.isEmpty {
            logger?.log(level: .debug, message: "Send to pool all transactions \(wrapped.count)")
            transactionSubject.onNext(wrapped)
        }
    }

    func sync(event: SynchronizerEvent) {
        switch event {
        case let .foundTransactions(transactions, inRange):
            logger?.log(level: .debug, message: "found \(transactions.count) mined txs in range: \(String(describing: inRange))")
            for overview in transactions {
                logger?.log(level: .debug, message: "tx: v =\(overview.value.decimalValue.decimalString) : fee = \(overview.fee?.decimalString() ?? "N/A") : height = \(overview.minedHeight?.description ?? "N/A")")
            }
            let lastBlockHeight = max(inRange?.upperBound ?? 0, lastBlockHeight)
            enqueue { [weak self] in
                guard let self else { return }
                let newTxs = await transactionPool?.sync(transactions: transactions, lastBlockHeight: lastBlockHeight) ?? []
                transactionSubject.onNext(newTxs)
            }
        case let .minedTransaction(pendingEntity):
            logger?.log(level: .debug, message: "found pending tx: v =\(pendingEntity.value.decimalValue.decimalString) : fee = \(pendingEntity.fee?.decimalString() ?? "N/A")")
            enqueue { [weak self] in
                await self?.update(transactions: [pendingEntity])
            }
        default:
            logger?.log(level: .debug, message: "Event: \(event)")
        }
    }

    func reSyncPending() {
        enqueue { [weak self] in
            guard let self else { return }
            let pending = await synchronizer.transactions.filter { overview in overview.minedHeight == nil }
            logger?.log(level: .debug, message: "Resync pending txs: \(pending.count)")
            for entity in pending {
                logger?.log(level: .debug, message: "TX : \(entity.value.decimalValue.description)")
            }
            if !pending.isEmpty {
                await update(transactions: pending)
            }
        }
    }

    private func update(transactions: [ZcashTransaction.Overview]) async {
        let newTxs = await transactionPool?.sync(transactions: transactions, lastBlockHeight: lastBlockHeight) ?? []
        logger?.log(level: .debug, message: "pool will update txs: \(newTxs.count)")
        transactionSubject.onNext(newTxs)
    }

    func transactionsSingle(paginationData: String?, filter: TransactionTypeFilter, descending: Bool, address: String?, limit: Int?) -> Single<[ZcashTransactionWrapper]> {
        transactionPool?.transactionsSingle(paginationData: paginationData, filter: filter, descending: descending, address: address, limit: limit) ?? .just([])
    }

    func rawTransaction(hash: String) -> String? {
        transactionPool?.transaction(by: hash)?.raw?.hs.hex
    }
}
