class DoubleSpendInfoPresenter {
    private let txHash: String
    private let conflictingTxHash: String

    weak var view: IDoubleSpendInfoView?

    init(txHash: String, conflictingTxHash: String) {
        self.txHash = txHash
        self.conflictingTxHash = conflictingTxHash
    }

}

extension DoubleSpendInfoPresenter: IDoubleSpendInfoViewDelegate {

    func onLoad() {
        view?.set(transactionHash: txHash, conflictingTransactionHash: conflictingTxHash)
    }

}
