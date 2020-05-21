class DoubleSpendInfoPresenter {
    private let txHash: String
    private let conflictingTxHash: String

    private let interactor: IDoubleSpendInfoInteractor
    weak var view: IDoubleSpendInfoView?

    init(interactor: IDoubleSpendInfoInteractor, txHash: String, conflictingTxHash: String) {
        self.interactor = interactor
        self.txHash = txHash
        self.conflictingTxHash = conflictingTxHash
    }

}

extension DoubleSpendInfoPresenter: IDoubleSpendInfoViewDelegate {

    func onLoad() {
        view?.set(transactionHash: txHash, conflictingTransactionHash: conflictingTxHash)
    }

    func onTapHash() {
        interactor.copy(value: txHash)
        view?.showCopied()
    }

    func onTapConflictingHash() {
        interactor.copy(value: conflictingTxHash)
        view?.showCopied()
    }

}
