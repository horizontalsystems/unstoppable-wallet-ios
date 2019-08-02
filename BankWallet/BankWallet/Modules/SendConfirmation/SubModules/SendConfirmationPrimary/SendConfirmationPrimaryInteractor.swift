class SendConfirmationPrimaryInteractor {
    private let pasteboardManager: IPasteboardManager

    init(pasteboardManager: IPasteboardManager) {
        self.pasteboardManager = pasteboardManager
    }

}

extension SendConfirmationPrimaryInteractor: ISendConfirmationPrimaryInteractor {

    func copy(receiver: String) {
        pasteboardManager.set(value: receiver)
    }

}
