import Foundation

class TransactionInfoPresenter {
    var interactor: ITransactionInfoInteractor
    let router: ITransactionInfoRouter
    var view: ITransactionInfoView?

    var coinCode: String
    var transactionHash: String

    init(interactor: ITransactionInfoInteractor, router: ITransactionInfoRouter, coinCode: String, transactionHash: String) {
        self.interactor = interactor
        self.router = router
        self.coinCode = coinCode
        self.transactionHash = transactionHash
    }

}

extension TransactionInfoPresenter: ITransactionInfoViewDelegate {

    func viewDidLoad() {
        interactor.getTransactionInfo(coinCode: coinCode, txHash: transactionHash)
    }

    func onLessMoreClick() {
    }

    func onCopyFromAddress() {
        interactor.onCopyFromAddress()
    }

    func destroy() {
        view = nil
    }
}

extension TransactionInfoPresenter: ITransactionInfoInteractorDelegate {

    func didGetTransactionInfo(txRecordViewItem: TransactionRecordViewItem) {
        view?.showTransactionItem(transactionRecordViewItem: txRecordViewItem)
    }

}