protocol IFullTransactionInfoView: class {

    func showError(providerName: String?)
    func hideError()

    func showLoading()
    func hideLoading()

    func reload()
    func showCopied()
}

protocol IFullTransactionInfoViewDelegate {
    func viewDidLoad()

    var providerName: String? { get }
    func numberOfSections() -> Int
    func numberOfRows(inSection section: Int) -> Int
    func section(_ section: Int) -> FullTransactionSection?

    func onRetryLoad()
    func onTap(item: FullTransactionItem)
    func onTapResourceCell()
    func onShare()
    func onClose()
}

protocol IFullTransactionInfoState {
    var transactionRecord: FullTransactionRecord? { get }
    var transactionHash: String { get }

    func set(transactionRecord: FullTransactionRecord)
}

protocol IFullTransactionInfoInteractor {
    var reachableConnection: Bool { get }

    func didLoad()

    func retrieveTransactionInfo(transactionHash: String)

    func url(for hash: String) -> String
    func copyToPasteboard(value: String)
}

protocol IFullTransactionInfoInteractorDelegate: class {
    func didReceive(transactionRecord: FullTransactionRecord)
    func onError(providerName: String?)

    func onConnectionChanged()

    func onOpen(url: String)
}

protocol IFullTransactionInfoRouter {
    func open(url: String)
    func share(value: String)
    func close()
}