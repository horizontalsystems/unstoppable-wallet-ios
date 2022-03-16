class AppStatusInteractor {
    private let appStatusManager: AppStatusManager
    private let pasteboardManager: PasteboardManager

    init(appStatusManager: AppStatusManager, pasteboardManager: PasteboardManager) {
        self.appStatusManager = appStatusManager
        self.pasteboardManager = pasteboardManager
    }

}

extension AppStatusInteractor: IAppStatusInteractor {

    var status: [(String, Any)] {
        appStatusManager.status
    }

    func copyToClipboard(string: String) {
        pasteboardManager.set(value: string)
    }

}
