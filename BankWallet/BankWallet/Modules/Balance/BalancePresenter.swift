import RxSwift

class BalancePresenter {
    private let interactor: IBalanceInteractor
    private let router: IBalanceRouter
    private let dataSource: BalanceItemDataSource
    private let factory: BalanceViewItemFactory

    weak var view: IBalanceView?

    init(interactor: IBalanceInteractor, router: IBalanceRouter, dataSource: BalanceItemDataSource, factory: BalanceViewItemFactory) {
        self.interactor = interactor
        self.router = router
        self.dataSource = dataSource
        self.factory = factory
    }

}

extension BalancePresenter: IBalanceInteractorDelegate {

    func didUpdate(wallets: [Wallet]) {
        dataSource.items = wallets.map { wallet in
            BalanceItem(title: wallet.title, coinCode: wallet.coinCode, refreshable: wallet.adapter.refreshable)
        }

        if let currency = dataSource.currency {
            interactor.fetchRates(currencyCode: currency.code, coinCodes: dataSource.coinCodes)
        }

        view?.reload()
    }

    func didUpdate(balance: Double, coinCode: CoinCode) {
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

}

extension BalancePresenter: IBalanceViewDelegate {

    func viewDidLoad() {
        interactor.initWallets()
    }

    var itemsCount: Int {
        return dataSource.count
    }

    func viewItem(at index: Int) -> BalanceViewItem {
        return factory.viewItem(from: dataSource.item(at: index), currency: dataSource.currency)
    }

    func headerViewItem() -> BalanceHeaderViewItem {
        return factory.headerViewItem(from: dataSource.items, currency: dataSource.currency)
    }

    func onRefresh(index: Int) {
        interactor.refresh(coinCode: dataSource.item(at: index).coinCode)
    }

    func onReceive(index: Int) {
        router.openReceive(for: dataSource.item(at: index).coinCode)
    }

    func onPay(index: Int) {
        router.openSend(for: dataSource.item(at: index).coinCode)
    }

    func onOpenManageCoins() {
        router.openManageCoins()
    }

}
