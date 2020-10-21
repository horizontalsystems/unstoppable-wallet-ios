import Foundation
import ZcashLightClientKit
import RxSwift

class ZCashTransactionPool {
    private var confirmedTransactions: Set<ZCashTransaction>
    private var pendingTransactions: Set<ZCashTransaction>

    private var transactions: [ZCashTransaction] {
        Array(confirmedTransactions.union(pendingTransactions)).sorted()
    }

    init(confirmedTransactions: [ConfirmedTransactionEntity], pendingTransactions: [PendingTransactionEntity]) {

        self.confirmedTransactions = Set(confirmedTransactions.compactMap { ZCashTransaction(confirmedTransaction: $0) })
        self.pendingTransactions = Set(pendingTransactions.compactMap { ZCashTransaction(pendingTransaction: $0) })
    }

    func add(pendingTransaction: PendingTransactionEntity) {
        guard let transaction = ZCashTransaction(pendingTransaction: pendingTransaction) else {
            return
        }

        pendingTransactions.update(with: transaction)
    }

    func add(confirmedTransaction: ConfirmedTransactionEntity) {
        guard let transaction = ZCashTransaction(confirmedTransaction: confirmedTransaction) else {
            return
        }

        confirmedTransactions.update(with: transaction)
    }

    func update(pendingTransactions: [PendingTransactionEntity]) {
        self.pendingTransactions = Set(pendingTransactions.compactMap { ZCashTransaction(pendingTransaction: $0) })
    }

    func updated(confirmedTransactions: [ConfirmedTransactionEntity]) -> [ZCashTransaction] {
        let newTransactions = confirmedTransactions.compactMap { ZCashTransaction(confirmedTransaction: $0) }
        self.confirmedTransactions = self.confirmedTransactions.union(Set(newTransactions))

        return newTransactions
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
