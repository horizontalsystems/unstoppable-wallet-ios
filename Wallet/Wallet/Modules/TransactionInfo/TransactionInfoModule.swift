import Foundation

protocol ITransactionInfoView: class {
    func showTransactionItem(transactionRecordViewItem: TransactionRecordViewItem)
    func expand()
    func lessen()
}

protocol ITransactionInfoViewDelegate: class {
    func viewDidLoad()
    func onLessMoreClick()
    func onCopyFromAddress()
    func destroy()
}

protocol ITransactionInfoInteractor {
    func getTransactionInfo(coinCode: String, txHash: String)
    func onCopyFromAddress()
}

protocol ITransactionInfoInteractorDelegate: class {
    func didGetTransactionInfo(txRecordViewItem: TransactionRecordViewItem)
}

protocol ITransactionInfoRouter {}
