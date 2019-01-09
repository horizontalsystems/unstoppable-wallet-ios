struct BalanceItem {
    let title: String
    let coinCode: CoinCode
    let refreshable: Bool

    var balance: Double = 0
    var state: AdapterState = .synced
    var rate: Rate?

    init(title: String, coinCode: CoinCode, refreshable: Bool) {
        self.title = title
        self.coinCode = coinCode
        self.refreshable = refreshable
    }

}
