class SendAddressInteractor {
    private let pasteboardManager: IPasteboardManager

    init(pasteboardManager: IPasteboardManager) {
        self.pasteboardManager = pasteboardManager
    }

}

extension SendAddressInteractor: ISendAddressInteractor {

    var valueFromPasteboard: String? {
        return pasteboardManager.value
    }

}