class AppStatusPresenter {
    weak var view: IAppStatusView?

    private let interactor: IAppStatusInteractor

    init(interactor: IAppStatusInteractor) {
        self.interactor = interactor
    }

}

extension AppStatusPresenter: IAppStatusViewDelegate {

    func viewDidLoad() {
        view?.set(logs: interactor.status)
    }

    func onCopy(text: String) {
        interactor.copyToClipboard(string: text)
    }

}
