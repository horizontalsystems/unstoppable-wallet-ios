import Foundation
import ZcashLightClientKit
import RxSwift

class ZCashTransactionPool {
    private var confirmedTransactions = Set<ZCashTransaction>()
    private var pendingTransactions = Set<ZCashTransaction>()

    private var transactions: [ZCashTransaction] {
        Array(confirmedTransactions.union(pendingTransactions)).sorted()
    }

    private func zCashTransactions(_ transactions: [SignedTransactionEntity]) -> [ZCashTransaction] {
        transactions.compactMap { tx in
            switch tx {
            case let tx as PendingTransactionEntity: return ZCashTransaction(pendingTransaction: tx)
            case let tx as ConfirmedTransactionEntity: return ZCashTransaction(confirmedTransaction: tx)
            default: return nil
            }
        }
    }

    @discardableResult private func sync(own: inout Set<ZCashTransaction>, incoming: [ZCashTransaction]) -> [ZCashTransaction] {
        var newTxs = [ZCashTransaction]()
        incoming.forEach { transaction in
            if own.insert(transaction).inserted {
                newTxs.append(transaction)
            }
        }
        return newTxs
    }

    func store(confirmedTransactions: [ConfirmedTransactionEntity], pendingTransactions: [PendingTransactionEntity]) {
        self.pendingTransactions = Set(zCashTransactions(pendingTransactions))
        self.confirmedTransactions = Set(zCashTransactions(confirmedTransactions))
    }

    func sync(transactions: [PendingTransactionEntity]) -> [ZCashTransaction] {
        sync(own: &pendingTransactions, incoming: zCashTransactions(transactions))
    }

    func sync(transactions: [ConfirmedTransactionEntity]) -> [ZCashTransaction] {
        sync(own: &confirmedTransactions, incoming: zCashTransactions(transactions))
    }

    func transaction(by hash: String) -> ZCashTransaction? {
        transactions.first { $0.transactionHash == hash }
    }

}

extension ZCashTransactionPool {

    func transactionsSingle(from: TransactionRecord?, limit: Int) -> Single<[ZCashTransaction]> {
        let transactions = self.transactions

        guard let transaction = from else {
            return Single.just(Array(transactions.prefix(limit)))
        }

        if let index = transactions.firstIndex(where: { $0.transactionHash == transaction.transactionHash }) {
            return Single.just((Array(transactions.suffix(from: index + 1).prefix(limit))))
        }
        return Single.just([])
    }

}
