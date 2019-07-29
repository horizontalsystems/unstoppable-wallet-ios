import Foundation

class BackupEosInteractor {
    private let pasteboardManager: IPasteboardManager

    init(pasteboardManager: IPasteboardManager) {
        self.pasteboardManager = pasteboardManager
    }

}

extension BackupEosInteractor: IBackupEosInteractor {

    func onCopy(string: String) {
        pasteboardManager.set(value: string)
    }

}
