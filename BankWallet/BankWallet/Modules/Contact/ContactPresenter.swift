class ContactPresenter {
    private let interactor: IContactInteractor
    private let router: IContactRouter

    weak var view: IContactView?

    init(interactor: IContactInteractor, router: IContactRouter) {
        self.interactor = interactor
        self.router = router
    }

}

extension ContactPresenter: IContactViewDelegate {

    func viewDidLoad() {
        view?.set(email: interactor.email)
        view?.set(telegramWalletHelperGroup: "@\(interactor.telegramWalletHelperGroup)")
        view?.set(telegramDevelopersGroup: "@\(interactor.telegramDevelopersGroup)")
    }

    func didTapEmail() {
        if router.canSendMail {
            router.openSendMail(recipient: interactor.email)
        } else {
            interactor.copyToClipboard(string: interactor.email)
            view?.showCopied()
        }
    }

    func didTapTelegramWalletHelp() {
        router.openTelegram(group: interactor.telegramWalletHelperGroup)
    }

    func didTapTelegramDevelopers() {
        router.openTelegram(group: interactor.telegramDevelopersGroup)
    }

    func didTapStatus() {
        router.openStatus()
    }

    func didTapDebugLog() {
        router.showDebugLog()
    }

}
