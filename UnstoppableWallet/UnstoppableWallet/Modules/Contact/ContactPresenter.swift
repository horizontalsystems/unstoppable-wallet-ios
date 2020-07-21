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
        view?.set(telegramWalletHelpAccount: "@\(interactor.telegramWalletHelpAccount)")
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
        router.openTelegram(account: interactor.telegramWalletHelpAccount)
    }

    func didTapDebugLog() {
        router.showDebugLog()
    }

}
