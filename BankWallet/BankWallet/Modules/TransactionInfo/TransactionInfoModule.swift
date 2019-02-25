protocol ITransactionInfoView: class {
    func showCopied()
}

protocol ITransactionInfoViewDelegate: class {
    func onCopy(value: String)
    func openFullInfo(coin: Coin, transactionHash: String)
}

protocol ITransactionInfoInteractor {
    func onCopy(value: String)
}

protocol ITransactionInfoInteractorDelegate: class {
}

protocol ITransactionInfoRouter {
    func openFullInfo(transactionHash: String, coin: Coin)
}
