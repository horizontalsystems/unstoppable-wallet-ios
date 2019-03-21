import RxSwift

class TransactionsPresenter {
    private let interactor: ITransactionsInteractor
    private let router: ITransactionsRouter
    private let factory: ITransactionViewItemFactory
    private let loader: TransactionsLoader
    private let dataSource: TransactionsMetadataDataSource

    weak var view: ITransactionsView?

    init(interactor: ITransactionsInteractor, router: ITransactionsRouter, factory: ITransactionViewItemFactory, loader: TransactionsLoader, dataSource: TransactionsMetadataDataSource) {
        self.interactor = interactor
        self.router = router
        self.factory = factory
        self.loader = loader
        self.dataSource = dataSource
    }

}

extension TransactionsPresenter: ITransactionLoaderDelegate {

    func fetchRecords(fetchDataList: [FetchData]) {
        interactor.fetchRecords(fetchDataList: fetchDataList)
    }

    func didChangeData() {
//        print("Reload View")

        view?.reload()
    }

    func reload(with diff: [IndexChange]) {
        view?.reload(with: diff)
    }

}

extension TransactionsPresenter: ITransactionsViewDelegate {

    func viewDidLoad() {
        interactor.initialFetch()
    }

    func onViewAppear() {
        view?.reload()
    }

    func onFilterSelect(coin: Coin?) {
        let coins = coin.map { [$0] } ?? []
        interactor.set(selectedCoins: coins)
    }

    var itemsCount: Int {
        return loader.itemsCount
    }

    func item(forIndex index: Int) -> TransactionViewItem {
        let item = loader.item(forIndex: index)
        let lastBlockHeight = dataSource.lastBlockHeight(coin: item.coin)
        let threshold = dataSource.threshold(coin: item.coin)
        let rate = dataSource.rate(coin: item.coin, timestamp: item.record.timestamp)

        interactor.fetchRates(timestampsData: [item.coin: [item.record.timestamp]])

        return factory.viewItem(fromItem: loader.item(forIndex: index), lastBlockHeight: lastBlockHeight, threshold: threshold, rate: rate)
    }

    func onBottomReached() {
        DispatchQueue.main.async {
//            print("On Bottom Reached")

            self.loader.loadNext()
        }
    }

    func onTransactionItemClick(index: Int) {
        router.openTransactionInfo(viewItem: item(forIndex: index))
    }

}

extension TransactionsPresenter: ITransactionsInteractorDelegate {

    func onUpdate(selectedCoins: [Coin]) {
//        print("Selected Coin Codes Updated: \(selectedCoins)")

        loader.set(coins: selectedCoins)
        loader.loadNext(initial: true)
    }

    func onUpdate(coinsData: [(Coin, Int, Int?)]) {
        var coins = [Coin]()

        for (coin, threshold, lastBlockHeight) in coinsData {
            coins.append(coin)
            dataSource.set(threshold: threshold, coin: coin)

            if let lastBlockHeight = lastBlockHeight {
                dataSource.set(lastBlockHeight: lastBlockHeight, coin: coin)
            }
        }

        interactor.fetchLastBlockHeights()

        if coins.count < 2 {
            view?.show(filters: [])
        } else {
            view?.show(filters: [nil] + coins)
        }

        loader.set(coins: coins)
        loader.loadNext(initial: true)
    }

    func onUpdateBaseCurrency() {
//        print("Base Currency Updated")

        dataSource.clearRates()
        view?.reload()
    }

    func onUpdate(lastBlockHeight: Int, coin: Coin) {
//        print("Last Block Height Updated: \(coin) - \(lastBlockHeight)")
        let oldLastBlockHeight = dataSource.lastBlockHeight(coin: coin)

        dataSource.set(lastBlockHeight: lastBlockHeight, coin: coin)

        if let threshold = dataSource.threshold(coin: coin), let oldLastBlockHeight = oldLastBlockHeight {
            let indexes = loader.itemIndexesForPending(coin: coin, blockHeight: oldLastBlockHeight - threshold)

            if !indexes.isEmpty {
                view?.reload(indexes: indexes)
            }
        } else {
            view?.reload()
        }
    }

    func didUpdate(records: [TransactionRecord], coin: Coin) {
        loader.didUpdate(records: records, coin: coin)
    }

    func didFetch(rateValue: Decimal, coin: Coin, currency: Currency, timestamp: Double) {
        dataSource.set(rate: CurrencyValue(currency: currency, value: rateValue), coin: coin, timestamp: timestamp)

        let indexes = loader.itemIndexes(coin: coin, timestamp: timestamp)

        if !indexes.isEmpty {
            view?.reload(indexes: indexes)
        }
    }

    func didFetch(recordsData: [Coin: [TransactionRecord]]) {
//        print("Did Fetch Records: \(records.map { key, value -> String in "\(key) - \(value.count)" })")

        loader.didFetch(recordsData: recordsData)
    }

    func onConnectionRestore() {
        view?.reload()
    }

}
