class FullTransactionInfoState: IFullTransactionInfoState {
    let transactionHash: String
    let coinCode: String
    var transactionRecord: FullTransactionRecord?

    func set(transactionRecord: FullTransactionRecord?) {
        self.transactionRecord = transactionRecord
    }

    init(coinCode: String, transactionHash: String) {
        self.coinCode = coinCode
        self.transactionHash = transactionHash
    }

}
