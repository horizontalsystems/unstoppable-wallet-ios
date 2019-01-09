protocol IBalanceView: class {
    func reload()
    func updateItem(at index: Int)
    func updateHeader()
}

protocol IBalanceViewDelegate {
    func viewDidLoad()

    var itemsCount: Int { get }
    func viewItem(at index: Int) -> BalanceViewItem
    func headerViewItem() -> BalanceHeaderViewItem

    func onRefresh(index: Int)
    func onReceive(index: Int)
    func onPay(index: Int)

    func onOpenManageCoins()
}

protocol IBalanceInteractor {
    func initWallets()
    func fetchRates(currencyCode: String, coinCodes: [CoinCode])

    func refresh(coinCode: CoinCode)
}

protocol IBalanceInteractorDelegate: class {
    func didUpdate(wallets: [Wallet])
    func didUpdate(balance: Double, coinCode: CoinCode)
    func didUpdate(state: AdapterState, coinCode: CoinCode)

    func didUpdate(currency: Currency)
    func didUpdate(rate: Rate)
}

protocol IBalanceRouter {
    func openReceive(for coinCode: CoinCode)
    func openSend(for coinCode: CoinCode)
    func openManageCoins()
}
