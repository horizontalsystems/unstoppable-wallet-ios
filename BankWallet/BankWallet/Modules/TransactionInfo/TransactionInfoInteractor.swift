class TransactionInfoInteractor {
    weak var delegate: ITransactionInfoInteractorDelegate?

    private let pasteboardManager: IPasteboardManager

    init(pasteboardManager: IPasteboardManager) {
        self.pasteboardManager = pasteboardManager
    }

}
extension TransactionInfoInteractor: ITransactionInfoInteractor {

    func onCopy(value: String) {
        pasteboardManager.set(value: value)
    }

}
