class BackupEosInteractor {
    private let pasteboardManager: IPasteboardManager

    init(pasteboardManager: IPasteboardManager) {
        self.pasteboardManager = pasteboardManager
    }

}

extension BackupEosInteractor: IBackupEosInteractor {

    func copyToClipboard(string: String) {
        pasteboardManager.set(value: string)
    }

}
