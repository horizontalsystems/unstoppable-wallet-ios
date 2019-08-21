class FullTransactionInfoState: IFullTransactionInfoState {
    let transactionHash: String
    let wallet: Wallet
    var transactionRecord: FullTransactionRecord?

    func set(transactionRecord: FullTransactionRecord?) {
        self.transactionRecord = transactionRecord
    }

    init(wallet: Wallet, transactionHash: String) {
        self.wallet = wallet
        self.transactionHash = transactionHash
    }

}
