protocol IBalanceView: class {
    func set(title: String)
    func show(totalBalance: CurrencyValue, upToDate: Bool)
    func show(items: [BalanceViewItem])
}

protocol IBalanceViewDelegate {
    func viewDidLoad()
    func onRefresh(for coin: Coin)
    func onReceive(for coin: Coin)
    func onPay(for coin: Coin)
}

protocol IBalanceInteractor {
    var baseCurrency: Currency { get }
    var wallets: [Wallet] { get }
    func rate(forCoin coin: Coin) -> Rate?
    func refresh(coin: Coin)
}

protocol IBalanceInteractorDelegate: class {
    func didUpdate()
}

protocol IBalanceRouter {
    func openReceive(for coin: Coin)
    func openSend(for coin: Coin)
}
