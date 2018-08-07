import Foundation
import WalletKit
import RealmSwift

class WalletSyncer {
    static let shared = WalletSyncer()

    init() {
        WalletKitProvider.shared.add(transactionListener: self)
    }
}

extension WalletSyncer: TransactionListener {

    func inserted(transactions: [Transaction]) {
        handle(transactions: transactions)
    }

    func modified(transactions: [Transaction]) {
        handle(transactions: transactions)
    }

    private func handle(transactions: [Transaction]) {
        let records = transactions.map { tx -> TransactionRecord in
            var totalInput: Int = 0
            var totalOutput: Int = 0

            for output in tx.inputs.flatMap({ $0.previousOutput }).filter({ $0.isMine }) {
                totalInput += output.value
            }

            for output in tx.outputs.filter({ $0.isMine }) {
                totalOutput += output.value
            }

            let record = TransactionRecord()
            record.transactionHash = tx.reversedHashHex
            record.coinCode = "BTC"
            record.amount = Int(totalOutput - totalInput)
            record.blockHeight = tx.block?.height ?? 0
            record.timestamp = tx.block?.header.timestamp ?? 0
            record.incoming = record.amount > 0
            return record
        }

        let realm = try! Realm()
        try? realm.write {
            for record in records {
                realm.add(record, update: true)
            }
        }
    }

}
