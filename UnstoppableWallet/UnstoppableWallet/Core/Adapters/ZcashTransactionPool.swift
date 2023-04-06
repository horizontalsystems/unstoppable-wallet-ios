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
        transactions.compactMap { ZcashTransactionWrapper(pendingTransaction: $0) }
    }

    private func zcashTransactions(_ transactions: [ZcashTransaction.Overview]) async -> [ZcashTransactionWrapper] {
        var wrapped = [ZcashTransactionWrapper]()
        for tx in transactions {
            if let tx = try? await transactionWithMemo(confirmedTransaction: tx) {
                wrapped.append(tx)
            }
        }
        return wrapped
    }

    private func transactionWithMemo(confirmedTransaction: ZcashTransaction.Overview) async throws -> ZcashTransactionWrapper? {
        let memos: [Memo] = (try? await synchronizer.getMemos(for: confirmedTransaction)) ?? []
        return ZcashTransactionWrapper(confirmedTransaction: confirmedTransaction, memo: memos.first)
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

    func store(confirmedTransactions: [ZcashTransaction.Overview], pendingTransactions: [PendingTransactionEntity]) async {
        self.pendingTransactions = Set(zcashTransactions(pendingTransactions))
        self.confirmedTransactions = Set(await zcashTransactions(confirmedTransactions))
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
