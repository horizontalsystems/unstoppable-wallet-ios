import RxSwift

class BalancePresenter {
    private static let sortingOnThreshold: Int = 5

    private var interactor: IBalanceInteractor
    private let router: IBalanceRouter
    private var dataSource: IBalanceItemDataSource
    private let factory: IBalanceViewItemFactory
    private let differ: IDiffer
    private let sortingOnThreshold: Int

    weak var view: IBalanceView?

    var walletToBackup: Wallet?

    init(interactor: IBalanceInteractor, router: IBalanceRouter, dataSource: IBalanceItemDataSource, factory: IBalanceViewItemFactory, differ: IDiffer, sortingOnThreshold: Int = BalancePresenter.sortingOnThreshold) {
        self.interactor = interactor
        self.router = router
        self.dataSource = dataSource
        self.factory = factory
        self.differ = differ
        self.sortingOnThreshold = sortingOnThreshold
    }

    private func updateStats() {
        if dataSource.statsButtonState == .selected {
            dataSource.items.forEach { item in
                interactor.syncStats(coinCode: item.wallet.coin.code, currencyCode: dataSource.currency.code)
            }
        }
    }

}

extension BalancePresenter: IBalanceInteractorDelegate {

    func didUpdate(wallets: [Wallet]) {
        let items: [BalanceItem] = wallets.map { wallet in
            let adapter = self.interactor.adapter(for: wallet)
            return BalanceItem(wallet: wallet, balance: adapter?.balance ?? 0, state: adapter?.state ?? .notReady)
        }

        dataSource.set(items: items)

        interactor.fetchRates(currencyCode: dataSource.currency.code, coinCodes: dataSource.coinCodes)
        updateStats()

        if dataSource.items.isEmpty {
            dataSource.statsButtonState = .hidden
        } else if dataSource.statsButtonState == .hidden {
            dataSource.statsButtonState = .normal
        }

        view?.setSort(isOn: dataSource.items.count >= sortingOnThreshold)
        view?.setStatsButton(state: dataSource.statsButtonState)
        view?.reload()
    }

    func didUpdate(balance: Decimal, wallet: Wallet) {
        if let index = dataSource.index(for: wallet) {
            let oldItems = dataSource.items
            dataSource.set(balance: balance, index: index)

            view?.reload(with: differ.changes(old: oldItems, new: dataSource.items))
            view?.updateHeader()
        }
    }

    func didUpdate(state: AdapterState, wallet: Wallet) {
        if let index = dataSource.index(for: wallet) {
            let oldItems = dataSource.items
            dataSource.set(state: state, index: index)

            view?.reload(with: differ.changes(old: oldItems, new: dataSource.items))
            view?.updateHeader()
        }
    }

    func didUpdate(currency: Currency) {
        dataSource.currency = currency
        dataSource.clearRates()

        interactor.fetchRates(currencyCode: currency.code, coinCodes: dataSource.coinCodes)
        updateStats()

        view?.reload()
    }

    func didUpdate(rate: Rate) {
        let indexes = dataSource.indexes(for: rate.coinCode)

        guard indexes.count > 0 else {
            return
        }

        if dataSource.statsButtonState == .selected {
            interactor.syncStats(coinCode: rate.coinCode, currencyCode: dataSource.currency.code)
        }

        let oldItems = dataSource.items
        for index in indexes {
            dataSource.set(rate: rate, index: index)
        }

        view?.reload(with: differ.changes(old: oldItems, new: dataSource.items))
        view?.updateHeader()
    }

    func didReceive(chartData: ChartData) {
        guard let points = chartData.stats[.day] else {
            return
        }
        guard let percentDelta = chartData.diffs[.day] else {
            return
        }

        let indexes = dataSource.indexes(for: chartData.coinCode)
        guard indexes.count > 0 else {
            return
        }

        let oldItems = dataSource.items
        for index in indexes {
            dataSource.set(chartPoints: points, percentDelta: percentDelta, index: index)
        }
        view?.reload(with: differ.changes(old: oldItems, new: dataSource.items))
    }

    func didFailStats(for coinCode: CoinCode) {
        let indexes = dataSource.indexes(for: coinCode)
        guard indexes.count > 0 else {
            return
        }

        let oldItems = dataSource.items
        for index in indexes {
            dataSource.setStatsFailed(index: index)
        }
        view?.reload(with: differ.changes(old: oldItems, new: dataSource.items))
    }

    func didRefresh() {
        view?.didRefresh()
    }

    func didBecomeActive() {
        updateStats()
    }

}

extension BalancePresenter: IBalanceViewDelegate {

    func viewDidLoad() {
        dataSource.sortType = interactor.sortType
        view?.setSort(isOn: false)
        view?.setStatsButton(state: dataSource.statsButtonState)

        interactor.initWallets()
    }

    var itemsCount: Int {
        return dataSource.items.count
    }

    func viewItem(at index: Int) -> BalanceViewItem {
        return factory.viewItem(from: dataSource.item(at: index), currency: dataSource.currency)
    }

    func headerViewItem() -> BalanceHeaderViewItem {
        return factory.headerViewItem(from: dataSource.items, currency: dataSource.currency)
    }

    func refresh() {
        interactor.refresh()
    }

    func onReceive(index: Int) {
        let wallet = dataSource.item(at: index).wallet
        if wallet.account.backedUp {
            router.openReceive(for: wallet)
        } else if let predefinedAccountType = interactor.predefinedAccountType(wallet: wallet) {
            walletToBackup = wallet
            view?.showBackupRequired(coin: wallet.coin, predefinedAccountType: predefinedAccountType)
        }
    }

    func onPay(index: Int) {
        router.openSend(wallet: dataSource.item(at: index).wallet)
    }

    func onChart(index: Int) {
        router.showChart(for: dataSource.item(at: index).wallet.coin.code)
    }

    func onOpenManageWallets() {
        router.openManageWallets()
    }

    func onSortTypeChange() {
        router.openSortType(selected: dataSource.sortType)
    }

    func didRequestBackup() {
        guard let wallet = walletToBackup, let predefinedAccountType = interactor.predefinedAccountType(wallet: wallet) else {
            return
        }
        router.openBackup(wallet: wallet, predefinedAccountType: predefinedAccountType)
    }

    func onStatsSwitch() {
        dataSource.statsButtonState = dataSource.statsButtonState == .selected ? .normal : .selected
        updateStats()

        view?.setStatsButton(state: dataSource.statsButtonState)
        view?.reload()
    }

}

extension BalancePresenter: ISortTypeDelegate {

    func onSelect(sort: BalanceSortType) {
        dataSource.sortType = sort
        if sort == .percentGrowth {
            dataSource.statsButtonState = .selected
            updateStats()

            view?.setStatsButton(state: dataSource.statsButtonState)
        }
        view?.reload()
    }

}
