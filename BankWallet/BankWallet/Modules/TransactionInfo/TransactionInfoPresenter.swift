class TransactionInfoPresenter {
    weak var view: ITransactionInfoView?

    private let interactor: ITransactionInfoInteractor
    private let router: ITransactionInfoRouter
    let viewItem: TransactionViewItem

    init(interactor: ITransactionInfoInteractor, router: ITransactionInfoRouter, viewItem: TransactionViewItem) {
        self.interactor = interactor
        self.router = router
        self.viewItem = viewItem
    }

}

extension TransactionInfoPresenter: ITransactionInfoViewDelegate {

    func onCopy(value: String) {
        interactor.onCopy(value: value)
        view?.showCopied()
    }

    func openFullInfo() {
        router.openFullInfo(transactionHash: viewItem.transactionHash, coin: viewItem.wallet.coin)
    }

}

extension TransactionInfoPresenter: ITransactionInfoInteractorDelegate {
}
