import RxSwift
import DeepDiff
import CurrencyKit
import CoinKit

class TransactionsPresenter {
    private let interactor: ITransactionsInteractor
    private let router: ITransactionsRouter
    private let factory: ITransactionViewItemFactory
    private let dataSource: TransactionRecordDataSource
    private var loading = false

    private var wallets = [Wallet]()

    weak var view: ITransactionsView?

    private var states = [Coin: AdapterState]()

    init(interactor: ITransactionsInteractor, router: ITransactionsRouter, factory: ITransactionViewItemFactory,
         dataSource: TransactionRecordDataSource) {
        self.interactor = interactor
        self.router = router
        self.factory = factory
        self.dataSource = dataSource
    }

    private func loadNext(initial: Bool = false) {
        guard !loading else {
            return
        }

        loading = true

        guard !dataSource.allShown else {
            if initial {
                //clear list on switch coins when data source has only one page
                view?.showNoTransactions()
            }

            loading = false
            return
        }

        interactor.fetchRecords(fetchDataList: dataSource.fetchDataList, initial: initial)
    }

}

extension TransactionsPresenter: ITransactionsViewDelegate {

    func viewDidLoad() {
        interactor.initialFetch()
    }

    func onFilterSelect(index: Int) {
        if index == 0 {
            interactor.set(selectedWallets: wallets)
        } else {
            interactor.set(selectedWallets: [wallets[index - 1]])
        }
    }

    func onBottomReached() {
        DispatchQueue.main.async {
            self.loadNext()
        }
    }

    func onTransactionClick(item: TransactionViewItem) {
        router.openTransactionInfo(viewItem: item)
    }

    func willShow(item: TransactionViewItem) {
        if item.currencyValue == nil {
            interactor.fetchRate(coin: item.wallet.coin, date: item.date)
        }
    }

}

extension TransactionsPresenter: ITransactionsInteractorDelegate {

    func onUpdate(selectedCoins: [Wallet]) {
        dataSource.set(wallets: selectedCoins)
        view?.set(status: factory.viewStatus(adapterStates: states, transactionsCount: dataSource.items.count))

        loadNext(initial: true)
    }

    func onUpdate(walletsData: [(Wallet, LastBlockInfo?)]) {
        dataSource.handleUpdated(walletsData: walletsData)
        interactor.fetchLastBlockHeights()

        wallets = walletsData.map { (wallet, _) in wallet }.sorted { wallet, wallet2 in wallet.coin.code < wallet2.coin.code }

        view?.show(filters: factory.filterItems(wallets: wallets))

        dataSource.handleUpdated(wallets: wallets)
        loadNext(initial: true)
    }

    func onUpdate(lastBlockInfo: LastBlockInfo, wallet: Wallet) {
        if dataSource.set(lastBlockInfo: lastBlockInfo, wallet: wallet) {
            view?.show(transactions: dataSource.items, animated: false)
        }
    }

    func onUpdateBaseCurrency() {
        dataSource.clearRates()
        view?.show(transactions: dataSource.items, animated: true)
    }

    func onConnectionRestore() {
        view?.reloadTransactions()
    }

    func didUpdate(records: [TransactionRecord], wallet: Wallet) {
        if let updatedViewItems = dataSource.handleUpdated(records: records, wallet: wallet) {
            view?.show(transactions: updatedViewItems, animated: true)

            view?.set(status: factory.viewStatus(adapterStates: states, transactionsCount: dataSource.items.count))
        }
    }

    func didFetch(rateValue: Decimal, coin: Coin, currency: Currency, date: Date) {
        if dataSource.set(rate: CurrencyValue(currency: currency, value: rateValue), coin: coin, date: date) {
            view?.show(transactions: dataSource.items, animated: false)
        }
    }

    func didFetch(recordsData: [Wallet: [TransactionRecord]], initial: Bool) {
        dataSource.handleNext(recordsData: recordsData)

        // called after load next or when pool has not enough items
        if dataSource.increasePage() {
            view?.show(transactions: dataSource.items, animated: true)
        } else if initial {
            view?.showNoTransactions()
        }
        view?.set(status: factory.viewStatus(adapterStates: states, transactionsCount: dataSource.items.count))

        loading = false
    }

    func onUpdate(states: [Coin: AdapterState]) {
        self.states = states

        view?.set(status: factory.viewStatus(adapterStates: states, transactionsCount: dataSource.items.count))
    }

    func didUpdate(state: AdapterState, wallet: Wallet) {
        states[wallet.coin] = state

        view?.set(status: factory.viewStatus(adapterStates: states, transactionsCount: dataSource.items.count))
    }

}
