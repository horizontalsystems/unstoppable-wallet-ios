import Foundation

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
        view?.setProvider(name: "Data Provider")

        tryLoadInfo()
    }

    var resource: String? {
        return state.transactionRecord?.resource
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
        interactor.retryLoadInfo()
    }

    func onTap(item: FullTransactionItem) {
        interactor.onTap(item: item)
    }

    func onTapResourceCell() {
        if let url = state.transactionRecord?.url {
            router.open(url: url + state.transactionHash)
        }
    }

    func onShare() {

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

    func onError() {
        view?.hideLoading()
        view?.showError()
    }

    func retryLoadInfo() {
        if state.transactionRecord == nil {
            tryLoadInfo()
        }
    }

    func onCopied() {
        view?.showCopied()
    }

    func onOpen(url: String) {
        router.open(url: url)
    }

}