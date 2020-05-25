class DoubleSpendInfoInteractor {
    private let pasteboardManager: IPasteboardManager

    init(pasteboardManager: IPasteboardManager) {
        self.pasteboardManager = pasteboardManager
    }

}

extension DoubleSpendInfoInteractor: IDoubleSpendInfoInteractor {

    func copy(value: String) {
        pasteboardManager.set(value: value)
    }

}
