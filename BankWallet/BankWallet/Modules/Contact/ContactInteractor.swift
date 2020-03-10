class ContactInteractor {
    private let appConfigProvider: IAppConfigProvider
    private let pasteboardManager: IPasteboardManager

    init(appConfigProvider: IAppConfigProvider, pasteboardManager: IPasteboardManager) {
        self.appConfigProvider = appConfigProvider
        self.pasteboardManager = pasteboardManager
    }

}

extension ContactInteractor: IContactInteractor {

    var email: String {
        appConfigProvider.reportEmail
    }

    var telegramWalletHelpAccount: String {
        appConfigProvider.telegramWalletHelpAccount
    }

    func copyToClipboard(string: String) {
        pasteboardManager.set(value: string)
    }

}
