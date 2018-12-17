protocol IBalanceView: class {
    func set(title: String)
    func show(totalBalance: CurrencyValue, upToDate: Bool)
    func show(items: [BalanceViewItem])
}

protocol IBalanceViewDelegate {
    func viewDidLoad()
    func onRefresh(for coinCode: CoinCode)
    func onReceive(for coinCode: CoinCode)
    func onPay(for coinCode: CoinCode)
}

protocol IBalanceInteractor {
    var baseCurrency: Currency { get }
    var wallets: [Wallet] { get }
    func rate(forCoin coinCode: CoinCode) -> Rate?
    func refresh(coinCode: CoinCode)
}

protocol IBalanceInteractorDelegate: class {
    func didUpdate()
}

protocol IBalanceRouter {
    func openReceive(for coinCode: CoinCode)
    func openSend(for coinCode: CoinCode)
}
