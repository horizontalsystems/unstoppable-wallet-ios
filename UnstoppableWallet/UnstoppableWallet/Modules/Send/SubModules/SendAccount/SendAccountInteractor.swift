class SendAccountInteractor {
    private let pasteboardManager: IPasteboardManager

    init(pasteboardManager: IPasteboardManager) {
        self.pasteboardManager = pasteboardManager
    }

}

extension SendAccountInteractor: ISendAccountInteractor {

    var valueFromPasteboard: String? {
        return pasteboardManager.value
    }

}
