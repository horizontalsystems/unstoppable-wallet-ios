class TransactionInfoInteractor {
    private let adapter: ITransactionsAdapter
    private let feeCoinProvider: IFeeCoinProvider
    private let pasteboardManager: IPasteboardManager

    init(adapter: ITransactionsAdapter, feeCoinProvider: IFeeCoinProvider, pasteboardManager: IPasteboardManager) {
        self.adapter = adapter
        self.feeCoinProvider = feeCoinProvider
        self.pasteboardManager = pasteboardManager
    }

}
extension TransactionInfoInteractor: ITransactionInfoInteractor {

    var lastBlockInfo: LastBlockInfo? {
        adapter.lastBlockInfo
    }

    var confirmationThreshold: Int {
        adapter.confirmationsThreshold
    }

    func transaction(hash: String) -> TransactionRecord? {
        adapter.transaction(hash: hash)
    }

    func rawTransaction(hash: String) -> String? {
        adapter.rawTransaction(hash: hash)
    }

    func feeCoin(coin: Coin) -> Coin? {
        feeCoinProvider.feeCoin(coin: coin)
    }

    func copy(value: String) {
        pasteboardManager.set(value: value)
    }

}
