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

}

extension FullTransactionInfoPresenter: IFullTransactionInfoViewDelegate {

    func viewDidLoad() {
        start()
    }

    private func start() {
        view?.showLoading()
        interactor.retrieveTransactionInfo(transactionHash: state.transactionHash)
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

}

extension FullTransactionInfoPresenter: IFullTransactionInfoInteractorDelegate {

    func didReceive(transactionRecord: FullTransactionRecord) {
        state.set(transactionRecord: transactionRecord)
        view?.hideLoading()
        view?.reload()
    }

}