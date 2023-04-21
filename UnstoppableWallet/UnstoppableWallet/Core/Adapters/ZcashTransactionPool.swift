import Foundation
import ZcashLightClientKit
import RxSwift

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

    private func zcashTransactions(_ transactions: [PendingTransactionEntity]) -> [ZcashTransactionWrapper] {
        transactions.compactMap { ZcashTransactionWrapper(tx: $0) }
    }

    private func zcashTransactions(_ transactions: [ZcashTransaction.Overview]) async -> [ZcashTransactionWrapper] {
        var wrapped = [ZcashTransactionWrapper]()
        for tx in transactions {
            if let tx = try? await transactionWithAdditional(tx: tx) {
                wrapped.append(tx)
            }
        }
        return wrapped
    }

    private func transactionWithAdditional(tx: ZcashTransaction.Overview) async throws -> ZcashTransactionWrapper? {
        let memos: [Memo] = (try? await synchronizer.getMemos(for: tx)) ?? []
        let recipients = await synchronizer.getRecipients(for: tx)
        return ZcashTransactionWrapper(tx: tx, memo: memos.first, recipient: recipients.first)
    }

    @discardableResult private func sync(own: inout Set<ZcashTransactionWrapper>, incoming: [ZcashTransactionWrapper]) -> [ZcashTransactionWrapper] {
        var newTxs = [ZcashTransactionWrapper]()
        incoming.forEach { transaction in
            if own.insert(transaction).inserted {
                newTxs.append(transaction)
            }
        }
        return newTxs
    }

    func initTransactions() async {
        let overviews = await synchronizer.clearedTransactions
        let pending = await synchronizer.pendingTransactions

        pendingTransactions = Set(zcashTransactions(pending))
        confirmedTransactions = Set(await zcashTransactions(overviews))
    }

    func sync(transactions: [PendingTransactionEntity]) -> [ZcashTransactionWrapper] {
        sync(own: &pendingTransactions, incoming: zcashTransactions(transactions))
    }

    func sync(transactions: [ZcashTransaction.Overview]) async -> [ZcashTransactionWrapper] {
        let txs = await zcashTransactions(transactions)
        return sync(own: &confirmedTransactions, incoming: txs)
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
            return Single.just((Array(transactions.suffix(from: index + 1).prefix(limit))))
        }
        return Single.just([])
    }

}
