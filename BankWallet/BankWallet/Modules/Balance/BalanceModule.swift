protocol IBalanceView: class {
    func set(title: String)
    func show(totalBalance: CurrencyValue?)
    func show(items: [BalanceViewItem])
    func show(syncStatus: String)
    func didRefresh()
}

protocol IBalanceViewDelegate {
    func viewDidLoad()
    func refresh()
    func onReceive(for coin: Coin)
    func onPay(for coin: Coin)
}

protocol IBalanceInteractor {
    var baseCurrency: Currency { get }
    var wallets: [Wallet] { get }
    func rate(forCoin coin: Coin) -> Rate?

    func refresh()
}

protocol IBalanceInteractorDelegate: class {
    func didUpdate()
    func didRefresh()
}

protocol IBalanceRouter {
    func openReceive(for coin: Coin)
    func openSend(for coin: Coin)
}
