class TransactionInfoPresenter {
    weak var view: ITransactionInfoView?

    private let interactor: ITransactionInfoInteractor
    private let router: ITransactionInfoRouter
    private let factory: ITransactionViewItemFactory

    init(interactor: ITransactionInfoInteractor, router: ITransactionInfoRouter, factory: ITransactionViewItemFactory) {
        self.interactor = interactor
        self.router = router
        self.factory = factory
    }

}

extension TransactionInfoPresenter: ITransactionInfoViewDelegate {

    func transactionViewItem(forTransactionHash hash: String) -> TransactionViewItem? {
        return interactor.transactionRecord(forTransactionHash: hash).map { record in
            factory.item(fromRecord: record)
        }
    }

    func onCopy(value: String) {
        interactor.onCopy(value: value)
        view?.showCopied()
    }

    func openFullInfo(transactionHash: String) {
        if let transactionRecord = interactor.transactionRecord(forTransactionHash: transactionHash) {
            router.openFullInfo(transactionHash: transactionHash, coinCode: transactionRecord.coinCode)
        }
    }

}

extension TransactionInfoPresenter: ITransactionInfoInteractorDelegate {
}
