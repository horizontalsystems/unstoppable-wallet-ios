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

    var email: String {
        return interactor.email
    }

    var telegramGroup: String {
        return "@\(interactor.telegramGroup)"
    }

    func didTapEmail() {
        if router.canSendMail {
            router.openSendMail(recipient: email)
        } else {
            interactor.copyToClipboard(string: interactor.email)
            view?.showCopied()
        }
    }

    func didTapTelegram() {
        router.openTelegram(group: interactor.telegramGroup)
    }

}

extension ReportPresenter: IReportInteractorDelegate {
}
