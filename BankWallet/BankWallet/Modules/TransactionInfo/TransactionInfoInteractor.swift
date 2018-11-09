class TransactionInfoInteractor {
    weak var delegate: ITransactionInfoInteractorDelegate?

    private let storage: ITransactionRecordStorage
    private let pasteboardManager: IPasteboardManager

    init(storage: ITransactionRecordStorage, pasteboardManager: IPasteboardManager) {
        self.storage = storage
        self.pasteboardManager = pasteboardManager
    }

}
extension TransactionInfoInteractor: ITransactionInfoInteractor {

    func transactionRecord(forTransactionHash hash: String) -> TransactionRecord? {
        return storage.record(forHash: hash)
    }

    func onCopy(value: String) {
        pasteboardManager.set(value: value)
    }

}
