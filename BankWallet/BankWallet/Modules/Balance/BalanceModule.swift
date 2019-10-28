import Foundation
import DeepDiff
import XRatesKit

protocol IBalanceView: class {
    func set(viewItems: [BalanceViewItem])
    func set(headerViewItem: BalanceHeaderViewItem)
    func set(statsButtonState: StatsButtonState)
    func set(sortIsOn: Bool)
    func showBackupRequired(coin: Coin, predefinedAccountType: IPredefinedAccountType)
    func didRefresh()
}

protocol IBalanceViewDelegate {
    func viewDidLoad()

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
    var wallets: [Wallet] { get }
    var baseCurrency: Currency { get }

    func marketInfo(coinCode: CoinCode, currencyCode: String) -> MarketInfo?
    func chartInfo(coinCode: CoinCode, currencyCode: String) -> ChartInfo?
    func balance(wallet: Wallet) -> Decimal?
    func state(wallet: Wallet) -> AdapterState?

    func subscribeToWallets()
    func subscribeToBaseCurrency()
    func subscribeToAdapters(wallets: [Wallet])

    func subscribeToMarketInfo(currencyCode: String)
    func subscribeToChartInfo(coinCodes: [CoinCode], currencyCode: String)
    func unsubscribeFromChartInfo()

    var sortType: BalanceSortType { get }

    func refresh()
    func predefinedAccountType(wallet: Wallet) -> IPredefinedAccountType?
}

protocol IBalanceInteractorDelegate: class {
    func didUpdate(wallets: [Wallet])
    func didUpdate(balance: Decimal, wallet: Wallet)
    func didUpdate(state: AdapterState, wallet: Wallet)

    func didUpdate(currency: Currency)
    func didUpdate(marketInfos: [CoinCode: MarketInfo])
    func didUpdate(chartInfo: ChartInfo, coinCode: CoinCode)

    func didRefresh()
}

protocol IBalanceRouter {
    func openReceive(for wallet: Wallet)
    func openSend(wallet: Wallet)
    func showChart(for coinCode: CoinCode)
    func openManageWallets()
    func openSortType(selected sort: BalanceSortType)
    func openBackup(wallet: Wallet, predefinedAccountType: IPredefinedAccountType)
}

protocol IBalanceViewItemFactory {
    func viewItem(item: BalanceItem, currency: Currency, isStatsOn: Bool) -> BalanceViewItem
    func headerViewItem(items: [BalanceItem], currency: Currency) -> BalanceHeaderViewItem
}

protocol IBalanceSorter {
    func sort(items: [BalanceItem], sort: BalanceSortType) -> [BalanceItem]
}

enum BalanceSortType: Int {
    case value
    case name
    case percentGrowth
}

enum StatsButtonState {
    case normal
    case hidden
    case selected
}
