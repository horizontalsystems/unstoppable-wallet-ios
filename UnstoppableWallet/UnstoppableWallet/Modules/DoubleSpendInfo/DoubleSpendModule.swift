protocol IDoubleSpendInfoView: AnyObject {
    func set(transactionHash: String, conflictingTransactionHash: String)
    func showCopied()
}

protocol IDoubleSpendInfoViewDelegate {
    func onLoad()
}
