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
        var newTx = [ZCashTransaction]()
        incoming.forEach { transaction in
            if own.insert(transaction).inserted {
                newTx.append(transaction)
            }
        }
        return newTx
    }

    func store(confirmedTransactions: [ConfirmedTransactionEntity], pendingTransactions: [PendingTransactionEntity]) {
        print("=======================================")
        print("Clear and storing again:")
        print("---- pending ----")
        pendingTransactions.forEach { print(description($0)) }
        self.pendingTransactions = Set(zCashTransactions(pendingTransactions))
        print("---- confirmed ----")
        confirmedTransactions.forEach { print(description($0)) }
        self.confirmedTransactions = Set(zCashTransactions(confirmedTransactions))
    }

    func add(pendingTransaction: PendingTransactionEntity) -> ZCashTransaction? {
        guard let transaction = ZCashTransaction(pendingTransaction: pendingTransaction) else {
            return nil
        }

        print(" ---> Mapped to: \(transaction.transactionHash)")
        print("pending txs: \(pendingTransactions)")

        pendingTransactions.update(with: transaction)
        return transaction
    }

    func add(confirmedTransaction: ConfirmedTransactionEntity) {
        guard let transaction = ZCashTransaction(confirmedTransaction: confirmedTransaction) else {
            return
        }

        confirmedTransactions.update(with: transaction)
    }

    func sync(transactions: [PendingTransactionEntity]) -> [ZCashTransaction] {
        print("=======================================")
        print("sync coming pending transactions:")
        transactions.forEach { print(description($0)) }

        let new = sync(own: &pendingTransactions, incoming: zCashTransactions(transactions))
        print("new transactions:")
        new.forEach { print($0.description) }

        return new
    }

    func sync(transactions: [ConfirmedTransactionEntity]) -> [ZCashTransaction] {
        print("=======================================")
        print("sync coming confirmed transactions:")
        transactions.forEach { print(description($0)) }

        let new = sync(own: &confirmedTransactions, incoming: zCashTransactions(transactions))
        print("new transactions:")
        new.forEach { print($0.description) }

        return new
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
