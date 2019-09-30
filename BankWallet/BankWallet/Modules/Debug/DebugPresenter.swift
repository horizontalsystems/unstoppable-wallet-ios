class DebugPresenter {
    private let interactor: IDebugInteractor

    weak var view: IDebugView?

    init(interactor: IDebugInteractor) {
        self.interactor = interactor
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
