class DebugPresenter {
    private let interactor: IDebugInteractor

    weak var view: IDebugView?

    init(interactor: IDebugInteractor) {
        self.interactor = interactor
    }

}

extension DebugPresenter: IDebugViewDelegate {

    func viewDidLoad() {
        view?.set(title: "Debug")
        view?.set(buttonTitle: "Clear")

        view?.set(logs: interactor.logs)
    }

    func didTapButton(text: String) {
        interactor.clearLogs()
        view?.set(logs: interactor.logs)
    }

}

extension DebugPresenter: IDebugInteractorDelegate {

    func didEnterForeground() {
        view?.set(logs: interactor.logs)
    }

}
