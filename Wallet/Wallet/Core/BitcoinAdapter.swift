import Foundation
import WalletKit
import RealmSwift

class BitcoinAdapter {
    private let walletKit: WalletKit
    private var transactionsNotificationToken: NotificationToken?

    weak var listener: IAdapterListener?

    init(walletKit: WalletKit) {
        self.walletKit = walletKit

        transactionsNotificationToken = walletKit.transactionsRealmResults.observe { [weak self] changes in
            self?.onTransactionsChanged(changes: changes)
        }
    }

    deinit {
        transactionsNotificationToken?.invalidate()
    }

    private func onTransactionsChanged(changes: RealmCollectionChange<Results<Transaction>>) {
        if case let .update(transactions, _, insertions, modifications) = changes {
            if !insertions.isEmpty {
                handle(transactions: insertions.map { transactions[$0] })
            }
            if !modifications.isEmpty {
                handle(transactions: modifications.map { transactions[$0] })
            }
        }
    }

    private func handle(transactions: [Transaction]) {
        let records = transactions.map { tx -> TransactionRecord in
            var totalInput: Int = 0
            var totalOutput: Int = 0

            for output in tx.inputs.flatMap({ $0.previousOutput }).filter({ $0.address != nil }) {
                totalInput += output.value
            }

            for output in tx.outputs.filter({ $0.address != nil }) {
                totalOutput += output.value
            }

            let record = TransactionRecord()
            record.transactionHash = tx.reversedHashHex
            record.coinCode = Bitcoin().code
            record.from = ""
            record.to = ""
            record.amount = Int(totalOutput - totalInput)
            record.fee = 0
            record.incoming = record.amount > 0
            record.blockHeight = tx.block?.height ?? 0
            record.timestamp = tx.block?.header.timestamp ?? 0
            return record
        }

        listener?.handle(transactionRecords: records)
    }

}

extension BitcoinAdapter: IAdapter {

    func showInfo() {
        walletKit.showRealmInfo()
    }

    func start() throws {
        try walletKit.start()
    }

    func send(to address: String, amount: Int) {

    }

}
