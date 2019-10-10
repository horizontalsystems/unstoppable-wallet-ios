class AppStatusPresenter {
    let interactor: IAppStatusInteractor
    weak var view: IDebugView?

    init(interactor: IAppStatusInteractor) {
        self.interactor = interactor
    }

}

extension AppStatusPresenter: IDebugViewDelegate {

    func viewDidLoad() {
        view?.set(title: "settings.report_problem.app_status")
        view?.set(buttonTitle: "button.copy")

        view?.set(logs: self.interactor.status)
    }

    func didTapButton(text: String) {
        interactor.copyToClipboard(string: text)
    }

}
