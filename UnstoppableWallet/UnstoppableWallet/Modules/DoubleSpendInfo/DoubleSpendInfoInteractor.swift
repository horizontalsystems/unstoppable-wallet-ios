class DoubleSpendInfoInteractor {
    private let pasteboardManager: PasteboardManager

    init(pasteboardManager: PasteboardManager) {
        self.pasteboardManager = pasteboardManager
    }

}

extension DoubleSpendInfoInteractor: IDoubleSpendInfoInteractor {

    func copy(value: String) {
        pasteboardManager.set(value: value)
    }

}
