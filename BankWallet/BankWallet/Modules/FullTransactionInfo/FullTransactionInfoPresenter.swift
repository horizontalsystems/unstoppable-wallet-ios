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
        interactor.updateProvider(for: state.wallet)

        view?.reload()
        tryLoadInfo()
    }

    var providerName: String? {
        state.transactionRecord?.providerName
    }

    var haveBlockExplorer: Bool {
        interactor.url(for: state.transactionHash) != nil
    }

    func numberOfSections() -> Int {
        state.transactionRecord?.sections.count ?? 0
    }

    func numberOfRows(inSection section: Int) -> Int {
        state.transactionRecord?.sections[section].items.count ?? 0
    }

    func section(_ section: Int) -> FullTransactionSection? {
        state.transactionRecord?.sections[section]
    }

    var transactionHash: String {
        state.transactionHash
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

    func onTapChangeResource() {
        router.openProviderSettings(coin: state.wallet.coin, transactionHash: state.transactionHash)
    }

    func onTapProviderLink() {
        router.open(url: interactor.url(for: state.transactionHash))
    }

    func onShare() {
        guard let url = interactor.url(for: state.transactionHash) else {
            return
        }
        router.share(value: url)
    }

    func onClose() {
        view?.hideLoading()
        router.close()
    }

    func onTapHash() {
        interactor.copyToPasteboard(value: state.transactionHash)
        view?.showCopied()
    }

}

extension FullTransactionInfoPresenter: IFullTransactionInfoInteractorDelegate {

    func onProviderChanged() {
        state.set(transactionRecord: nil)
        view?.reload()

        interactor.updateProvider(for: state.wallet)
        tryLoadInfo()
    }

    func didReceive(transactionRecord: FullTransactionRecord) {
        state.set(transactionRecord: transactionRecord)
        view?.hideLoading()
        view?.reload()
    }

    func onProviderOffline(providerName: String?) {
        view?.hideLoading()
        view?.showOffline(providerName: providerName)
    }

    func onTransactionNotFound(providerName: String?) {
        view?.hideLoading()
        view?.showError(providerName: providerName)
    }

    func onConnectionChanged() {
        onRetryLoad()
    }

}