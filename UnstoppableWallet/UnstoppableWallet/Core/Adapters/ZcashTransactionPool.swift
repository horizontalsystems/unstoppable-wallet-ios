import Foundation
import RxSwift
import ZcashLightClientKit

class ZcashTransactionPool {
    private var confirmedTransactions = Set<ZcashTransactionWrapper>()
    private var pendingTransactions = Set<ZcashTransactionWrapper>()
    private let synchronizer: Synchronizer
    private let receiveAddress: SaplingAddress

    init(receiveAddress: SaplingAddress, synchronizer: Synchronizer) {
        self.receiveAddress = receiveAddress
        self.synchronizer = synchronizer
    }

    private func transactions(filter: TransactionTypeFilter) -> [ZcashTransactionWrapper] {
        var confirmedTransactions = confirmedTransactions
        var pendingTransactions = pendingTransactions
        switch filter {
        case .all: ()
        case .incoming:
            confirmedTransactions = confirmedTransactions.filter { !$0.isSentTransaction }
            pendingTransactions = pendingTransactions.filter { !$0.isSentTransaction }
        case .outgoing:
            confirmedTransactions = confirmedTransactions.filter { $0.isSentTransaction }
            pendingTransactions = pendingTransactions.filter { !$0.isSentTransaction }
        default:
            confirmedTransactions = []
            pendingTransactions = []
        }

        return Array(confirmedTransactions.union(pendingTransactions)).sorted()
    }

    private func zcashTransactions(_ transactions: [ZcashTransaction.Overview], lastBlockHeight: Int) async -> [ZcashTransactionWrapper] {
        var wrapped = [ZcashTransactionWrapper]()
        for tx in transactions {
            if let tx = try? await transactionWithAdditional(tx: tx, lastBlockHeight: lastBlockHeight) {
                wrapped.append(tx)
            }
        }
        return wrapped
    }

    private func transactionWithAdditional(tx: ZcashTransaction.Overview, lastBlockHeight: Int) async throws -> ZcashTransactionWrapper? {
        let memos: [Memo] = (try? await synchronizer.getMemos(for: tx)) ?? []
        let firstMemo = memos
            .compactMap { $0.toString() }
            .first

        let recipients = await synchronizer.getRecipients(for: tx)
        let firstAddress = recipients
            .filter { $0.hasAddress }
            .first

        return ZcashTransactionWrapper(tx: tx, memo: firstMemo, recipient: firstAddress, lastBlockHeight: lastBlockHeight)
    }

    private func sync(own: inout Set<ZcashTransactionWrapper>, incoming: [ZcashTransactionWrapper]) {
        incoming.forEach { transaction in own.insert(transaction) }
    }

    func initTransactions() async {
        let overviews = await synchronizer.transactions
//        let pending = await synchronizer.pendingTransactions

//        pendingTransactions = await Set(zcashTransactions(pending, lastBlockHeight: 0))
        confirmedTransactions = Set(await zcashTransactions(overviews, lastBlockHeight: 0))
    }

    func sync(transactions: [ZcashTransaction.Overview], lastBlockHeight: Int) async -> [ZcashTransactionWrapper] {
        let txs = await zcashTransactions(transactions, lastBlockHeight: lastBlockHeight)
        // TODO: sync pending and confirmed but How?
        sync(own: &confirmedTransactions, incoming: txs)
        return txs
    }

    func transaction(by hash: String) -> ZcashTransactionWrapper? {
        transactions(filter: .all).first { $0.transactionHash == hash }
    }
}

extension ZcashTransactionPool {
    var all: [ZcashTransactionWrapper] {
        transactions(filter: .all)
    }

    func transactionsSingle(from: TransactionRecord?, filter: TransactionTypeFilter, limit: Int) -> RxSwift.Single<[ZcashTransactionWrapper]> {
        let transactions = transactions(filter: filter)

        guard let transaction = from else {
            return Single.just(Array(transactions.prefix(limit)))
        }

        if let index = transactions.firstIndex(where: { $0.transactionHash == transaction.transactionHash }) {
            return Single.just(Array(transactions.suffix(from: index + 1).prefix(limit)))
        }
        return Single.just([])
    }
}

extension TransactionRecipient {
    var hasAddress: Bool {
        switch self {
        case .address: return true
        case .internalAccount: return false
        }
    }
}
