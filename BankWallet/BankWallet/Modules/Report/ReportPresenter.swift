class ReportPresenter {
    private let interactor: IReportInteractor
    private let router: IReportRouter

    weak var view: IReportView?

    init(interactor: IReportInteractor, router: IReportRouter) {
        self.interactor = interactor
        self.router = router
    }

}

extension ReportPresenter: IReportViewDelegate {

    func viewDidLoad() {
        view?.set(email: interactor.email)
        view?.set(telegramGroup: "@\(interactor.telegramGroup)")
    }

    func didTapEmail() {
        if router.canSendMail {
            router.openSendMail(recipient: interactor.email)
        } else {
            interactor.copyToClipboard(string: interactor.email)
            view?.showCopied()
        }
    }

    func didTapTelegram() {
        router.openTelegram(group: interactor.telegramGroup)
    }

    func didTapStatus() {
        router.openStatus()
    }

}
