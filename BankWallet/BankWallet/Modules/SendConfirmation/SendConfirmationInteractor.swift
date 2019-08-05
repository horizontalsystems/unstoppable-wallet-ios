class SendConfirmationInteractor {
    private let pasteboardManager: IPasteboardManager

    init(pasteboardManager: IPasteboardManager) {
        self.pasteboardManager = pasteboardManager
    }

}

extension SendConfirmationInteractor: ISendConfirmationInteractor {

    func copy(receiver: String) {
        pasteboardManager.set(value: receiver)
    }

}
