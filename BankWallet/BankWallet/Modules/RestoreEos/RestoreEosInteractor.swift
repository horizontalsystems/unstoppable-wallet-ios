class RestoreEosInteractor {
    weak var delegate: IRestoreEosInteractorDelegate?

    private let pasteboardManager: IPasteboardManager
    private let appConfigProvider: IAppConfigProvider

    init(pasteboardManager: IPasteboardManager, appConfigProvider: IAppConfigProvider) {
        self.pasteboardManager = pasteboardManager
        self.appConfigProvider = appConfigProvider
    }
}

extension RestoreEosInteractor: IRestoreEosInteractor {

    var defaultCredentials: (String, String) {
        appConfigProvider.defaultEosCredentials
    }

    var valueFromPasteboard: String? {
        return pasteboardManager.value
    }

    func validate(privateKey: String) throws {
        try EosAdapter.validate(privateKey: privateKey)
    }

    func validate(account: String) throws {
        try EosAdapter.validate(account: account)
    }

}
