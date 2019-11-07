protocol ITransactionInfoView: class {
    func showCopied()
}

protocol ITransactionInfoViewDelegate: class {
    var viewItem: TransactionViewItem { get }
    func onCopy(value: String)
    func openFullInfo()
    func openLockInfo()
}

protocol ITransactionInfoInteractor {
    func onCopy(value: String)
}

protocol ITransactionInfoInteractorDelegate: class {
}

protocol ITransactionInfoRouter {
    func openFullInfo(transactionHash: String, wallet: Wallet)
    func openLockInfo()
}
