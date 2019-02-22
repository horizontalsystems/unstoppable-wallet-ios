class TransactionItemFactory {

    func create(coin: Coin, record: TransactionRecord) -> TransactionItem {
        return TransactionItem(coin: coin, record: record)
    }

}
