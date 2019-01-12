protocol IFullTransactionInfoView: class {

    func showError()
    func hideError()

    func showLoading()
    func hideLoading()

    func reload()
    func showCopied()
//
//    func reload()
}

protocol IFullTransactionInfoViewDelegate {
    func viewDidLoad()

    var providerName: String { get }
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

    var providerName: String { get }
    var fullUrl: String { get }

    func set(transactionRecord: FullTransactionRecord)
}

protocol IFullTransactionInfoInteractor {
    func retrieveTransactionInfo(transactionHash: String)
    func retryLoadInfo()

    func onTap(item: FullTransactionItem)
}

protocol IFullTransactionInfoInteractorDelegate: class {
    func didReceive(transactionRecord: FullTransactionRecord)
    func onError()

    func retryLoadInfo()

    func onCopied()
    func onOpen(url: String)
}

protocol IFullTransactionInfoRouter {
    func open(url: String)
    func share(value: String)
    func close()
}