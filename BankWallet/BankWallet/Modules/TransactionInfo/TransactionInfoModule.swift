import UIKit

protocol ITransactionInfoView: class {
    func showTransactionItem(transactionRecordViewItem: TransactionViewItem)
    func expand()
    func lessen()
}

protocol ITransactionInfoViewDelegate: class {
    func viewDidLoad()
    func onLessMoreClick()
    func onCopyFromAddress()
    func onShowFullInfo()
    func onCreate(controller: UIViewController)
    func destroy()
}

protocol ITransactionInfoInteractor {
    func getTransactionInfo()
    func onCopyFromAddress()
}

protocol ITransactionInfoInteractorDelegate: class {
    func didGetTransactionInfo(txRecordViewItem: TransactionViewItem)
}

protocol ITransactionInfoRouter {
    func showFullInfo(transaction: TransactionViewItem)
    func onCreate(controller: UIViewController)
}
