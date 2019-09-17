import Foundation
import DeepDiff

protocol IBalanceView: class {
    func reload()
    func reload(with diff: [Change<BalanceItem>])
    func updateHeader()
    func didRefresh()
    func setStatsButton(isHidden: Bool)
    func setStatsButton(highlighted: Bool)
    func setSort(isOn: Bool)
    func showBackupRequired(coin: Coin, predefinedAccountType: IPredefinedAccountType)
}

protocol IBalanceViewDelegate {
    func viewDidLoad()

    var itemsCount: Int { get }
    func viewItem(at index: Int) -> BalanceViewItem
    func headerViewItem() -> BalanceHeaderViewItem

    func refresh()

    func onReceive(index: Int)
    func onPay(index: Int)
    func onChart(index: Int)

    func onOpenManageWallets()

    func onSortTypeChange()
    func didRequestBackup()
    func onStatsSwitch()
}

protocol IBalanceInteractor {
    var sortType: BalanceSortType { get }

    func adapter(for wallet: Wallet) -> IBalanceAdapter?
    func initWallets()
    func fetchRates(currencyCode: String, coinCodes: [CoinCode])
    func refresh()
    func predefinedAccountType(wallet: Wallet) -> IPredefinedAccountType?
    func syncStats(coinCode: CoinCode, currencyCode: String)
}

protocol IBalanceInteractorDelegate: class {
    func didUpdate(wallets: [Wallet])
    func didUpdate(balance: Decimal, wallet: Wallet)
    func didUpdate(state: AdapterState, wallet: Wallet)

    func didUpdate(currency: Currency)
    func didUpdate(rate: Rate)

    func didReceive(chartData: ChartData)
    func didFailStats(for coinCode: CoinCode)

    func didRefresh()
    func didBecomeActive()
}

protocol IBalanceRouter {
    func openReceive(for wallet: Wallet)
    func openSend(wallet: Wallet)
    func showChart(for coinCode: CoinCode)
    func openManageWallets()
    func openSortType(selected sort: BalanceSortType)
    func openBackup(wallet: Wallet, predefinedAccountType: IPredefinedAccountType)
}

protocol IBalanceItemDataSource {
    var statsModeOn: Bool { get set }
    var sortType: BalanceSortType { get set }
    var items: [BalanceItem] { get }
    var currency: Currency { get set }
    var coinCodes: [CoinCode] { get }
    func item(at index: Int) -> BalanceItem
    func index(for wallet: Wallet) -> Int?
    func indexes(for coinCode: String) -> [Int]

    func set(balance: Decimal, index: Int)
    func set(state: AdapterState, index: Int)
    func set(rate: Rate, index: Int)
    func set(chartPoints: [ChartPoint], percentDelta: Decimal, index: Int)
    func setStatsFailed(index: Int)
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
    case percentGrowth
}
