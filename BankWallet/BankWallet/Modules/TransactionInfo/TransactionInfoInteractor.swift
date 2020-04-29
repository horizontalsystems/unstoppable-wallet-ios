class TransactionInfoInteractor {
    private let pasteboardManager: IPasteboardManager

    init(pasteboardManager: IPasteboardManager) {
        self.pasteboardManager = pasteboardManager
    }

}
extension TransactionInfoInteractor: ITransactionInfoInteractor {

    func copy(value: String) {
        pasteboardManager.set(value: value)
    }

}
