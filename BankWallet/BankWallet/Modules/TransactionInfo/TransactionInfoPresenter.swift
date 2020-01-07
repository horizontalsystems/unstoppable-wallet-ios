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
        router.openFullInfo(transactionHash: viewItem.transactionHash, wallet: viewItem.wallet)
    }

    func openLockInfo() {
        router.openLockInfo()
    }

    func openDoubleSpendInfo() {
        router.openDoubleSpendInfo(txHash: viewItem.transactionHash, conflictingTxHash: viewItem.conflictingTxHash)
    }

}

extension TransactionInfoPresenter: ITransactionInfoInteractorDelegate {
}
