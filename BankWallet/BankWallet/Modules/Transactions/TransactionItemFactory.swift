class TransactionItemFactory {

    func create(wallet: Wallet, record: TransactionRecord) -> TransactionItem {
        return TransactionItem(wallet: wallet, record: record)
    }

}
