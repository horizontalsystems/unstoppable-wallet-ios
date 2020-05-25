protocol IFullTransactionInfoView: class {

    func showOffline(providerName: String?)
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
    var haveBlockExplorer: Bool { get }
    func numberOfSections() -> Int
    func numberOfRows(inSection section: Int) -> Int
    func section(_ section: Int) -> FullTransactionSection?
    var transactionHash: String { get }

    func onRetryLoad()
    func onTap(item: FullTransactionItem)
    func onTapChangeResource()
    func onTapProviderLink()
    func onShare()
    func onClose()
    func onTapHash()
}

protocol IFullTransactionInfoState {
    var transactionRecord: FullTransactionRecord? { get }
    var wallet: Wallet { get }
    var transactionHash: String { get }

    func set(transactionRecord: FullTransactionRecord?)
}

protocol IFullTransactionInfoInteractor {
    var reachableConnection: Bool { get }

    func didLoad()
    func updateProvider(for wallet: Wallet)

    func retrieveTransactionInfo(transactionHash: String)

    func url(for hash: String) -> String?
    func copyToPasteboard(value: String)
}

protocol IFullTransactionInfoInteractorDelegate: class {
    func onProviderChanged()

    func didReceive(transactionRecord: FullTransactionRecord)
    func onProviderOffline(providerName: String?)
    func onTransactionNotFound(providerName: String?)

    func onConnectionChanged()
}

protocol IFullTransactionInfoRouter {
    func openProviderSettings(coin: Coin, transactionHash: String)
    func open(url: String?)
    func share(value: String)
    func close()
}