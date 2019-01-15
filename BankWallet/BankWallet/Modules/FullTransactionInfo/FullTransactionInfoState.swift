class FullTransactionInfoState: IFullTransactionInfoState {
    let transactionHash: String
    var transactionRecord: FullTransactionRecord?

    func set(transactionRecord: FullTransactionRecord) {
        self.transactionRecord = transactionRecord
    }

    init(transactionHash: String) {
        self.transactionHash = transactionHash
    }

}
