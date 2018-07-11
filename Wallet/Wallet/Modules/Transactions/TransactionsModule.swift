import Foundation
import WalletKit

protocol ITransactionsView: class {
    func show(items: [TransactionRecordViewItem], changeSet: CollectionChangeSet?)
}

protocol ITransactionsViewDelegate {
    func viewDidLoad()
}

protocol ITransactionsInteractor {
    func retrieveTransactionRecords()
}

protocol ITransactionsInteractorDelegate: class {
    func didRetrieve(items: [TransactionRecordViewItem], changeSet: CollectionChangeSet?)
}

protocol ITransactionsRouter {
}
