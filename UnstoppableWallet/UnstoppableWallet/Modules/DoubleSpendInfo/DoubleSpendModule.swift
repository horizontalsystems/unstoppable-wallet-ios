protocol IDoubleSpendInfoView: AnyObject {
    func set(transactionHash: String, conflictingTransactionHash: String)
    func showCopied()
}

protocol IDoubleSpendInfoViewDelegate {
    func onLoad()
    func onTapHash()
    func onTapConflictingHash()
}

protocol IDoubleSpendInfoInteractor {
    func copy(value: String)
}
