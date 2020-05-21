class DoubleSpendInfoPresenter {
    let txHash: String
    let conflictingTxHash: String

    private let interactor: IDoubleSpendInfoInteractor
    weak var view: IDoubleSpendInfoView?

    init(interactor: IDoubleSpendInfoInteractor, txHash: String, conflictingTxHash: String) {
        self.interactor = interactor
        self.txHash = txHash
        self.conflictingTxHash = conflictingTxHash
    }

}

extension DoubleSpendInfoPresenter: IDoubleSpendInfoViewDelegate {

    func onTapHash() {
        interactor.copy(value: txHash)
        view?.showCopied()
    }

    func onConflictingTapHash() {
        interactor.copy(value: conflictingTxHash)
        view?.showCopied()
    }

}
