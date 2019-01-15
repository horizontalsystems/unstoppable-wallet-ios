class FullTransactionInfoPresenter {
    private let router: IFullTransactionInfoRouter
    private let interactor: IFullTransactionInfoInteractor
    private let state: IFullTransactionInfoState
    weak var view: IFullTransactionInfoView?

    init(interactor: IFullTransactionInfoInteractor, router: IFullTransactionInfoRouter, state: IFullTransactionInfoState) {
        self.interactor = interactor
        self.router = router
        self.state = state
    }

    private func tryLoadInfo() {
        view?.hideError()
        view?.showLoading()

        interactor.retrieveTransactionInfo(transactionHash: state.transactionHash)
    }
}

extension FullTransactionInfoPresenter: IFullTransactionInfoViewDelegate {

    func viewDidLoad() {
        interactor.didLoad()

        tryLoadInfo()
    }

    var providerName: String? {
        return state.transactionRecord?.providerName
    }

    func numberOfSections() -> Int {
        return state.transactionRecord?.sections.count ?? 0
    }

    func numberOfRows(inSection section: Int) -> Int {
        return state.transactionRecord?.sections[section].items.count ?? 0
    }

    func section(_ section: Int) -> FullTransactionSection? {
        return state.transactionRecord?.sections[section]
    }

    func onRetryLoad() {
        if state.transactionRecord == nil, interactor.reachableConnection {
            tryLoadInfo()
        }
    }

    func onTap(item: FullTransactionItem) {
        guard item.clickable else {
            return
        }

        if let url = item.url {
            router.open(url: url)
        }

        if let value = item.value {
            interactor.copyToPasteboard(value: value)
            view?.showCopied()
        }
    }

    func onTapResourceCell() {
        router.open(url: interactor.url(for: state.transactionHash))
    }

    func onShare() {
        router.share(value: interactor.url(for: state.transactionHash))
    }

    func onClose() {
        view?.hideLoading()
        router.close()
    }

}

extension FullTransactionInfoPresenter: IFullTransactionInfoInteractorDelegate {

    func didReceive(transactionRecord: FullTransactionRecord) {
        state.set(transactionRecord: transactionRecord)
        view?.hideLoading()
        view?.reload()
    }

    func onError(providerName: String?) {
        view?.hideLoading()
        view?.showError(providerName: providerName)
    }

    func onConnectionChanged() {
        onRetryLoad()
    }

    func onOpen(url: String) {
        router.open(url: url)
    }

}