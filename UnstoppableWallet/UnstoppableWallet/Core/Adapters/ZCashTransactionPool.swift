import Foundation
import ZcashLightClientKit
import RxSwift

class ZCashTransactionPool {
    private var transactions = [ZCashTransaction]()

    init(clearedTransactions: [ConfirmedTransactionEntity], pendingTransactions: [PendingTransactionEntity]) {

        transactions.append(contentsOf: pendingTransactions.map { ZCashTransaction(pendingTransaction: $0) })
        transactions.append(contentsOf: clearedTransactions.map { ZCashTransaction(confirmedTransaction: $0) })

        transactions.sort()
    }

}

extension ZCashTransactionPool {

    func transactionsSingle(from: TransactionRecord?, limit: Int) -> Single<[ZCashTransaction]> {
        guard let transaction = from else {
            return Single.just(Array(transactions.prefix(limit)))
        }

        if let index = transactions.firstIndex(where: { $0.transactionHash == transaction.transactionHash}) {
            return Single.just((Array(transactions.suffix(from: index + 1).prefix(limit))))
        }
        return Single.just([])
    }

}

