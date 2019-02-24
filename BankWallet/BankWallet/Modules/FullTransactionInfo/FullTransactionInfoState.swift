class FullTransactionInfoState: IFullTransactionInfoState {
    let transactionHash: String
    let coin: Coin
    var transactionRecord: FullTransactionRecord?

    func set(transactionRecord: FullTransactionRecord?) {
        self.transactionRecord = transactionRecord
    }

    init(coin: Coin, transactionHash: String) {
        self.coin = coin
        self.transactionHash = transactionHash
    }

}
