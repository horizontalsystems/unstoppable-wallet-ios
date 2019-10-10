class AppStatusInteractor {

    let appStatusManager: IAppStatusManager
    let pasteboardManager: IPasteboardManager

    init(appStatusManager: IAppStatusManager, pasteboardManager: IPasteboardManager) {
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
