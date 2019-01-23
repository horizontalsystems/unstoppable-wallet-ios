class TransactionItemFactory {

    func create(coinCode: CoinCode, record: TransactionRecord) -> TransactionItem {
        return TransactionItem(coinCode: coinCode, record: record)
    }

}
