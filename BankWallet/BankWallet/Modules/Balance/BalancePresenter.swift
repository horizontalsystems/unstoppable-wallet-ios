import RxSwift

class BalancePresenter {
    private let interactor: IBalanceInteractor
    private let router: IBalanceRouter
    private var dataSource: IBalanceItemDataSource
    private let factory: IBalanceViewItemFactory
    private let predefinedAccountTypeManager: IPredefinedAccountTypeManager
    private let differ: IDiffer
    private let sortingOnThreshold: Int

    weak var view: IBalanceView?

    init(interactor: IBalanceInteractor, router: IBalanceRouter, dataSource: IBalanceItemDataSource, factory: IBalanceViewItemFactory, predefinedAccountTypeManager: IPredefinedAccountTypeManager, differ: IDiffer, sortingOnThreshold: Int) {
        self.interactor = interactor
        self.router = router
        self.dataSource = dataSource
        self.factory = factory
        self.predefinedAccountTypeManager = predefinedAccountTypeManager
        self.differ = differ
        self.sortingOnThreshold = sortingOnThreshold
    }

}

extension BalancePresenter: IBalanceInteractorDelegate {

    func didUpdate(wallets: [Wallet]) {
        let items: [BalanceItem] = wallets.map { wallet in
            let adapter = self.interactor.adapter(for: wallet)
            return BalanceItem(wallet: wallet, balance: adapter?.balance ?? 0, state: adapter?.state ?? .notReady)
        }

        dataSource.set(items: items)

        if let currency = dataSource.currency {
            interactor.fetchRates(currencyCode: currency.code, coinCodes: dataSource.coinCodes)
        }

        view?.setSort(isOn: dataSource.items.count > sortingOnThreshold)
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

        view?.reload()
    }

    func didUpdate(rate: Rate) {
        let indices = dataSource.indices(for: rate.coinCode)

        guard indices.count > 0 else {
            return
        }

        let oldItems = dataSource.items
        for index in indices {
            dataSource.set(rate: rate, index: index)
        }

        view?.reload(with: differ.changes(old: oldItems, new: dataSource.items))
        view?.updateHeader()
    }

    func didRefresh() {
        view?.didRefresh()
    }

}

extension BalancePresenter: IBalanceViewDelegate {

    func viewDidLoad() {
        dataSource.sortType = interactor.sortType
        view?.setSort(isOn: false)

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
        } else {
            view?.showBackupAlert(index: index)
        }
    }

    func onPay(index: Int) {
        router.openSend(for: dataSource.item(at: index).wallet.coin.code)
    }

    func onOpenManageWallets() {
        router.openManageWallets()
    }

    func onSortTypeChange() {
        router.openSortType(selected: dataSource.sortType)
    }

    func onBackup(index: Int) {
        let wallet = dataSource.item(at: index).wallet
        let pat = predefinedAccountTypeManager.allTypes.first { $0.supports(accountType: wallet.account.type) }
        if let pat = pat {
            router.openBackup(wallet: wallet, predefinedAccountType: pat)
        }
    }

}

extension BalancePresenter: ISortTypeDelegate {

    func onSelect(sort: BalanceSortType) {
        dataSource.sortType = sort
        view?.reload()
    }

}
