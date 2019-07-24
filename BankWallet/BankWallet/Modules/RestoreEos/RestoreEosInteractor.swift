class RestoreEosInteractor {
    private let pasteboardManager: IPasteboardManager

    weak var delegate: IRestoreEosInteractorDelegate?

    init(pasteboardManager: IPasteboardManager) {
        self.pasteboardManager = pasteboardManager
    }
}

extension RestoreEosInteractor: IRestoreEosInteractor {

    var valueFromPasteboard: String? {
        return pasteboardManager.value
    }

    func validate(privateKey: String) throws {
        try EosAdapter.validate(privateKey: privateKey)
    }

}
