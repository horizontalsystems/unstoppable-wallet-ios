protocol IFullTransactionInfoView: class {
    func show()

//    func showError()
//    func hideError()
//
    func showLoading()
    func hideLoading()

    func reload()
    func showCopied()
//
//    func reload()
}

protocol IFullTransactionInfoViewDelegate {
    func viewDidLoad()

    var resource: String? { get }
    func numberOfSections() -> Int
    func numberOfRows(inSection section: Int) -> Int
    func section(_ section: Int) -> FullTransactionSection?
}

protocol IFullTransactionInfoState {
    var transactionRecord: FullTransactionRecord? { get }
    var transactionHash: String { get }

    func set(transactionRecord: FullTransactionRecord)
}

protocol IFullTransactionInfoInteractor {
    func retrieveTransactionInfo(transactionHash: String)
}

protocol IFullTransactionInfoInteractorDelegate: class {
    func didReceive(transactionRecord: FullTransactionRecord)
}

protocol IFullTransactionInfoRouter {
}