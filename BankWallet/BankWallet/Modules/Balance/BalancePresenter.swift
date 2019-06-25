import RxSwift

class BalancePresenter {
    private let interactor: IBalanceInteractor
    private let router: IBalanceRouter
    private var state: BalancePresenterState
    private var dataSource: IBalanceItemDataSource
    private let factory: IBalanceViewItemFactory
    private let sortingOnThreshold: Int

    weak var view: IBalanceView?

    init(interactor: IBalanceInteractor, router: IBalanceRouter, state: BalancePresenterState, dataSource: IBalanceItemDataSource, factory: IBalanceViewItemFactory, sortingOnThreshold: Int) {
        self.interactor = interactor
        self.router = router
        self.state = state
        self.dataSource = dataSource
        self.factory = factory
        self.sortingOnThreshold = sortingOnThreshold
    }

}

extension BalancePresenter: IBalanceInteractorDelegate {

    func didUpdate(adapters: [IAdapter]) {
        let items = adapters.map { adapter in
            BalanceItem(coin: adapter.coin, refreshable: adapter.refreshable)
        }
        dataSource.set(items: items, sort: state.sort, desc: state.desc)

        if let currency = dataSource.currency {
            interactor.fetchRates(currencyCode: currency.code, coinCodes: dataSource.coinCodes)
        }

        view?.setSort(isOn: dataSource.items.count > sortingOnThreshold)
        view?.reload()
    }

    func didUpdate(balance: Decimal, coinCode: CoinCode) {
        if let index = dataSource.index(for: coinCode) {
            dataSource.set(balance: balance, index: index)

            view?.updateItem(at: index)
            view?.updateHeader()
        }
    }

    func didUpdate(state: AdapterState, coinCode: CoinCode) {
        if let index = dataSource.index(for: coinCode) {
            dataSource.set(state: state, index: index)

            view?.updateItem(at: index)
            view?.updateHeader()
        }
    }

    func didUpdate(currency: Currency) {
        dataSource.currency = currency
        dataSource.clearRates()

        interactor.fetchRates(currencyCode: currency.code, coinCodes: dataSource.coinCodes)

        view?.reload()
    }

    func didUpdate(rate: Rate) {
        if let index = dataSource.index(for: rate.coinCode) {
            dataSource.set(rate: rate, index: index)

            view?.updateItem(at: index)
            view?.updateHeader()
        }
    }

    func didRefresh() {
        view?.didRefresh()
    }

}

extension BalancePresenter: IBalanceViewDelegate {

    func viewDidLoad() {
        view?.setSort(isOn: false)

        interactor.initAdapters()

        view?.setSortDirection(desc: state.desc)
        view?.setSortLabel(key: state.sort.rawValue)
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
        router.openReceive(for: dataSource.item(at: index).coin)
    }

    func onPay(index: Int) {
        router.openSend(for: dataSource.item(at: index).coin.code)
    }

    func onOpenManageCoins() {
        router.openManageCoins()
    }

    func onSortDirectionChange() {
        state.desc = !state.desc
        view?.setSortDirection(desc: state.desc)
        dataSource.sort(type: state.sort, desc: state.desc)
        view?.reload()
    }

    func onSortTypeChange() {
        router.openSortType(selected: state.sort)
    }

}

extension BalancePresenter: ISortTypeDelegate {

    func onSelect(sort: BalanceSortType) {
        state.sort = sort
        view?.setSortLabel(key: state.sort.rawValue)
        dataSource.sort(type: state.sort, desc: state.desc)
        view?.reload()
    }

}
