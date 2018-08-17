import UIKit

protocol ITransactionInfoView: class {
    func showTransactionItem(transactionRecordViewItem: TransactionRecordViewItem)
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
    func getTransactionInfo(coinCode: String, txHash: String)
    func onCopyFromAddress()
}

protocol ITransactionInfoInteractorDelegate: class {
    func didGetTransactionInfo(txRecordViewItem: TransactionRecordViewItem)
}

protocol ITransactionInfoRouter {
    func showFullInfo(transaction: TransactionRecordViewItem)
    func onCreate(controller: UIViewController)
}
