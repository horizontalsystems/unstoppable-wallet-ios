import Foundation
import DeepDiff
import XRatesKit
import CurrencyKit

protocol IBalanceView: class {
    func set(headerViewItem: BalanceHeaderViewItem?, viewItems: [BalanceViewItem])
    func hideRefresh()
    func show(error: Error)
    func showLostAccounts()
}

protocol IBalanceViewDelegate {
    func onLoad()
    func onAppear()
    func onDisappear()

    func onTriggerRefresh()

    func onTap(viewItem: BalanceViewItem)
    func onTapReceive(viewItem: BalanceViewItem)
    func onTapPay(viewItem: BalanceViewItem)
    func onTapSwap(viewItem: BalanceViewItem)
    func onTapChart(viewItem: BalanceViewItem)
    func onTapFailedIcon(viewItem: BalanceViewItem)

    func onTapAddCoin()

    func onTapSortType()

    func onTapHideBalance()
    func onTapShowBalance()
}

protocol IBalanceInteractor: AnyObject {
    var wallets: [Wallet] { get }
    var baseCurrency: Currency { get }

    func marketInfo(coinCode: CoinCode, currencyCode: String) -> MarketInfo?
    func balance(wallet: Wallet) -> Decimal?
    func balanceLocked(wallet: Wallet) -> Decimal?
    func state(wallet: Wallet) -> AdapterState?

    func subscribeToWallets()
    func subscribeToAdapters(wallets: [Wallet])

    func subscribeToMarketInfo(currencyCode: String)

    var sortType: SortType { get }
    var balanceHidden: Bool { get set }

    func refresh()
    func predefinedAccountType(wallet: Wallet) -> PredefinedAccountType?

    func notifyAppear()
    func notifyDisappear()
}

protocol IBalanceInteractorDelegate: class {
    func didUpdate(wallets: [Wallet])
    func didPrepareAdapters()
    func didUpdate(balance: Decimal, balanceLocked: Decimal?, wallet: Wallet)
    func didUpdate(state: AdapterState, wallet: Wallet)

    func didUpdate(currency: Currency)
    func didUpdate(marketInfos: [CoinCode: MarketInfo])

    func didUpdate(sortType: SortType)

    func didRefresh()
    func onLostAccounts()
}

protocol IBalanceRouter {
    func showReceive(wallet: Wallet)
    func openSend(wallet: Wallet)
    func openSwap(wallet: Wallet)
    func showChart(coin: Coin)
    func openManageWallets()
    func showBackupRequired(wallet: Wallet, predefinedAccountType: PredefinedAccountType)
    func showSortType()
    func showSyncError(error: Error, wallet: Wallet)
}

protocol IBalanceViewItemFactory {
    func viewItem(item: BalanceItem, currency: Currency, balanceHidden: Bool, expanded: Bool) -> BalanceViewItem
    func headerViewItem(items: [BalanceItem], currency: Currency, sortingOnThreshold: Int) -> BalanceHeaderViewItem
}

protocol IBalanceSorter {
    func sort(items: [BalanceItem], sort: SortType) -> [BalanceItem]
}
