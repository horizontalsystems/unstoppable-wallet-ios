class DebugPresenter {
    private let interactor: IDebugInteractor
    private let router: IDebugRouter

    weak var view: IDebugView?

    init(interactor: IDebugInteractor, router: IDebugRouter) {
        self.interactor = interactor
        self.router = router
    }

}

extension DebugPresenter: IDebugViewDelegate {

    func viewDidLoad() {
        view?.set(logs: interactor.logs)
    }

    func didTapClear() {
        interactor.clearLogs()
    }

}

extension DebugPresenter: IDebugInteractorDelegate {

    func didEnterForeground() {
        view?.set(logs: interactor.logs)
    }

    func didClearLogs() {
        view?.set(logs: interactor.logs)
    }

}
