import RxSwift
import XRatesKit

class BalancePresenter {
    private static let sortingOnThreshold: Int = 5

    weak var view: IBalanceView?

    private var interactor: IBalanceInteractor
    private let router: IBalanceRouter
    private let factory: IBalanceViewItemFactory
    private let sorter: IBalanceSorter
    private let sortingOnThreshold: Int

    var walletToBackup: Wallet?

    private var items = [BalanceItem]()
    private var currency: Currency
    private var sortType: BalanceSortType
    private var isStatsOn = false

    init(interactor: IBalanceInteractor, router: IBalanceRouter, factory: IBalanceViewItemFactory, sorter: IBalanceSorter, sortingOnThreshold: Int = BalancePresenter.sortingOnThreshold) {
        self.interactor = interactor
        self.router = router
        self.factory = factory
        self.sorter = sorter
        self.sortingOnThreshold = sortingOnThreshold

        currency = interactor.baseCurrency
        sortType = interactor.sortType
    }

    private func handleUpdate(wallets: [Wallet]) {
        items = interactor.wallets.map { BalanceItem(wallet: $0) }

        for item in items {
            item.balance = interactor.balance(wallet: item.wallet)
            item.state = interactor.state(wallet: item.wallet)
        }

        interactor.subscribeToAdapters(wallets: wallets)

        handleRates()
        handleStats()

        view?.set(sortIsOn: items.count >= sortingOnThreshold)
        updateStatsButtonState()
    }

    private func handleRates() {
        for item in items {
            item.marketInfo = interactor.marketInfo(coinCode: item.wallet.coin.code, currencyCode: currency.code)
        }

        interactor.subscribeToMarketInfo(currencyCode: currency.code)
    }

    private func handleStats() {
        if isStatsOn {
            for item in items {
                item.chartInfo = interactor.chartInfo(coinCode: item.wallet.coin.code, currencyCode: currency.code)
            }

            interactor.subscribeToChartInfo(coinCodes: items.map { $0.wallet.coin.code }, currencyCode: currency.code)
        } else {
            interactor.unsubscribeFromChartInfo()
        }
    }

    private func updateViewItems() {
        items = sorter.sort(items: items, sort: sortType)

        let viewItems = items.map {
            factory.viewItem(item: $0, currency: currency, isStatsOn: isStatsOn)
        }

        view?.set(viewItems: viewItems)
    }

    private func updateHeaderViewItem() {
        let viewItem = factory.headerViewItem(items: items, currency: currency)
        view?.set(headerViewItem: viewItem)
    }

    private func updateStatsButtonState() {
        let statsButtonState: StatsButtonState

        if items.isEmpty {
            statsButtonState = .hidden
        } else if isStatsOn {
            statsButtonState = .selected
        } else {
            statsButtonState = .normal
        }

        view?.set(statsButtonState: statsButtonState)
    }

}

extension BalancePresenter: IBalanceViewDelegate {

    func viewDidLoad() {
        handleUpdate(wallets: interactor.wallets)

        interactor.subscribeToWallets()
        interactor.subscribeToBaseCurrency()

        updateViewItems()
        updateHeaderViewItem()
    }

    func refresh() {
        interactor.refresh()
    }

    func onReceive(index: Int) {
        let wallet = items[index].wallet

        if wallet.account.backedUp {
            router.openReceive(for: wallet)
        } else if let predefinedAccountType = interactor.predefinedAccountType(wallet: wallet) {
            walletToBackup = wallet
            view?.showBackupRequired(coin: wallet.coin, predefinedAccountType: predefinedAccountType)
        }
    }

    func onPay(index: Int) {
        router.openSend(wallet: items[index].wallet)
    }

    func onChart(index: Int) {
        router.showChart(for: items[index].wallet.coin.code)
    }

    func onOpenManageWallets() {
        router.openManageWallets()
    }

    func onSortTypeChange() {
        router.openSortType(selected: sortType)
    }

    func didRequestBackup() {
        guard let wallet = walletToBackup, let predefinedAccountType = interactor.predefinedAccountType(wallet: wallet) else {
            return
        }
        router.openBackup(wallet: wallet, predefinedAccountType: predefinedAccountType)
    }

    func onStatsSwitch() {
        isStatsOn = !isStatsOn

        handleStats()

        updateViewItems()
        updateStatsButtonState()
    }

}

extension BalancePresenter: IBalanceInteractorDelegate {

    func didUpdate(wallets: [Wallet]) {
        handleUpdate(wallets: wallets)

        updateViewItems()
        updateHeaderViewItem()
    }

    func didUpdate(balance: Decimal, wallet: Wallet) {
        guard let item = items.first(where: { $0.wallet == wallet }) else {
            return
        }

        item.balance = balance

        updateViewItems()
        updateHeaderViewItem()
    }

    func didUpdate(state: AdapterState, wallet: Wallet) {
        guard let item = items.first(where: { $0.wallet == wallet }) else {
            return
        }

        item.state = state

        updateViewItems()
        updateHeaderViewItem()
    }

    func didUpdate(currency: Currency) {
        self.currency = currency
        handleRates()

        updateViewItems()
        updateHeaderViewItem()
    }

    func didUpdate(marketInfos: [CoinCode: MarketInfo]) {
        for (coinCode, marketInfo) in marketInfos {
            for item in items {
                if item.wallet.coin.code == coinCode {
                    item.marketInfo = marketInfo
                }
            }
        }

        updateViewItems()
        updateHeaderViewItem()
    }

    func didUpdate(chartInfo: ChartInfo, coinCode: CoinCode) {
        for item in items {
            if item.wallet.coin.code == coinCode {
                item.chartInfo = chartInfo
            }
        }

        updateViewItems()
    }

    func didRefresh() {
        view?.didRefresh()
    }

}

extension BalancePresenter: ISortTypeDelegate {

    func onSelect(sort: BalanceSortType) {
        sortType = sort

        if sort == .percentGrowth && isStatsOn == false {
            isStatsOn = true
            handleStats()

            updateStatsButtonState()
        }

        updateViewItems()
    }

}
