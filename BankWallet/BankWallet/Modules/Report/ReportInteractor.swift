class ReportInteractor {
    private let appConfigProvider: IAppConfigProvider
    private let pasteboardManager: IPasteboardManager

    init(appConfigProvider: IAppConfigProvider, pasteboardManager: IPasteboardManager) {
        self.appConfigProvider = appConfigProvider
        self.pasteboardManager = pasteboardManager
    }

}

extension ReportInteractor: IReportInteractor {

    var email: String {
        return appConfigProvider.reportEmail
    }

    var telegramGroup: String {
        return appConfigProvider.reportTelegramGroup
    }

    func copyToClipboard(string: String) {
        pasteboardManager.set(value: string)
    }

}
