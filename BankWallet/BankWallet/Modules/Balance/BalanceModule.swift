import Foundation

protocol IBalanceView: class {
    func reload()
    func updateItem(at index: Int)
    func updateHeader()
    func didRefresh()
}

protocol IBalanceViewDelegate {
    func viewDidLoad()

    var itemsCount: Int { get }
    func viewItem(at index: Int) -> BalanceViewItem
    func headerViewItem() -> BalanceHeaderViewItem

    func refresh()

    func onReceive(index: Int)
    func onPay(index: Int)

    func onOpenManageCoins()
}

protocol IBalanceInteractor {
    func initAdapters()
    func fetchRates(currencyCode: String, coinCodes: [CoinCode])
    func refresh()
}

protocol IBalanceInteractorDelegate: class {
    func didUpdate(adapters: [IAdapter])
    func didUpdate(balance: Decimal, coinCode: CoinCode)
    func didUpdate(state: AdapterState, coinCode: CoinCode)

    func didUpdate(currency: Currency)
    func didUpdate(rate: Rate)

    func didRefresh()
}

protocol IBalanceRouter {
    func openReceive(for coinCode: CoinCode)
    func openSend(for coinCode: CoinCode)
    func openManageCoins()
}
