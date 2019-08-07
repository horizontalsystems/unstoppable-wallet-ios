import Foundation
import DeepDiff

protocol IBalanceView: class {
    func reload()
    func reload(with diff: [Change<BalanceItem>])
    func updateHeader()
    func didRefresh()
    func setSort(isOn: Bool)
}

protocol IBalanceViewDelegate {
    func viewDidLoad()

    var itemsCount: Int { get }
    func viewItem(at index: Int) -> BalanceViewItem
    func headerViewItem() -> BalanceHeaderViewItem

    func refresh()

    func onReceive(index: Int)
    func onPay(index: Int)

    func onOpenManageWallets()

    func onSortTypeChange()
}

protocol IBalanceInteractor {
    var sortType: BalanceSortType { get }
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
    func openReceive(for coin: Coin)
    func openSend(for coinCode: CoinCode)
    func openManageWallets()
    func openSortType(selected sort: BalanceSortType)
}

protocol IBalanceItemDataSource {
    var sortType: BalanceSortType { get set }
    var items: [BalanceItem] { get }
    var currency: Currency? { get set }
    var coinCodes: [CoinCode] { get }
    func item(at index: Int) -> BalanceItem
    func index(for coinCode: CoinCode) -> Int?

    func set(balance: Decimal, index: Int)
    func set(state: AdapterState, index: Int)
    func set(rate: Rate, index: Int)
    func clearRates()
    func set(items: [BalanceItem])
}

protocol IBalanceViewItemFactory {
    func viewItem(from item: BalanceItem, currency: Currency?) -> BalanceViewItem
    func headerViewItem(from items: [BalanceItem], currency: Currency?) -> BalanceHeaderViewItem
}

protocol IBalanceSorter {
    func sort(items: [BalanceItem], sort: BalanceSortType) -> [BalanceItem]
}

enum BalanceSortType: Int {
    case value
    case name
}
