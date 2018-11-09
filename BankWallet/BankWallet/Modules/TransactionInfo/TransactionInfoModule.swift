protocol ITransactionInfoView: class {
    func showCopied()
}

protocol ITransactionInfoViewDelegate: class {
    func transactionViewItem(forTransactionHash hash: String) -> TransactionViewItem?
    func onCopy(value: String)
}

protocol ITransactionInfoInteractor {
    func transactionRecord(forTransactionHash hash: String) -> TransactionRecord?
    func onCopy(value: String)
}

protocol ITransactionInfoInteractorDelegate: class {
}

protocol ITransactionInfoRouter {
}
