class SendConfirmationInteractor {
    private let pasteboardManager: PasteboardManager

    init(pasteboardManager: PasteboardManager) {
        self.pasteboardManager = pasteboardManager
    }

}

extension SendConfirmationInteractor: ISendConfirmationInteractor {

    func copy(receiver: String) {
        pasteboardManager.set(value: receiver)
    }

}
