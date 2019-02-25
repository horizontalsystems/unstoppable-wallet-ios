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

    func onCopy(value: String) {
        interactor.onCopy(value: value)
        view?.showCopied()
    }

    func openFullInfo(coin: Coin, transactionHash: String) {
        router.openFullInfo(transactionHash: transactionHash, coin: coin)
    }

}

extension TransactionInfoPresenter: ITransactionInfoInteractorDelegate {
}
