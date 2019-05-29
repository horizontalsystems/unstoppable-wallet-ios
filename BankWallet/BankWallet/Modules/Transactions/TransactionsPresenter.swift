import RxSwift
import DeepDiff

class TransactionsPresenter {
    private let interactor: ITransactionsInteractor
    private let router: ITransactionsRouter
    private let factory: ITransactionViewItemFactory
    private let loader: TransactionsLoader
    private let dataSource: TransactionsMetadataDataSource
    private let transactionsDiffer: ITransactionViewItemDataSource

    weak var view: ITransactionsView?

    init(interactor: ITransactionsInteractor, router: ITransactionsRouter, factory: ITransactionViewItemFactory, loader: TransactionsLoader, dataSource: TransactionsMetadataDataSource, transactionsDiffer: ITransactionViewItemDataSource) {
        self.interactor = interactor
        self.router = router
        self.factory = factory
        self.loader = loader
        self.dataSource = dataSource
        self.transactionsDiffer = transactionsDiffer
    }

}

extension TransactionsPresenter: ITransactionViewItemDataSourceDelegate {

    func createViewItem(for item: TransactionItem) -> TransactionViewItem {
        let lastBlockHeight = dataSource.lastBlockHeight(coin: item.coin)
        let threshold = dataSource.threshold(coin: item.coin)
        let rate = dataSource.rate(coin: item.coin, date: item.record.date)

        if rate == nil {
            interactor.fetchRate(coin: item.coin, date: item.record.date)
        }

        return factory.viewItem(fromItem: item, lastBlockHeight: lastBlockHeight, threshold: threshold, rate: rate)
    }

    func reload(with diff: [Change<TransactionViewItem>], items: [TransactionViewItem], animated: Bool) {
        view?.reload(with: diff, items: items, animated: animated)
    }

}

extension TransactionsPresenter: ITransactionLoaderDelegate {

    func fetchRecords(fetchDataList: [FetchData]) {
        interactor.fetchRecords(fetchDataList: fetchDataList)
    }

    func reload(with newItems: [TransactionItem], animated: Bool) {
        transactionsDiffer.reload(with: newItems, animated: animated)
    }

    func add(items: [TransactionItem]) {
        transactionsDiffer.add(items: items)
    }

}

extension TransactionsPresenter: ITransactionsViewDelegate {

    func viewDidLoad() {
        interactor.initialFetch()
    }

    func onViewAppear() {
        transactionsDiffer.reloadAll()
    }

    func onFilterSelect(coin: Coin?) {
        let coins = coin.map { [$0] } ?? []
        interactor.set(selectedCoins: coins)
    }

    func onBottomReached() {
        DispatchQueue.main.async {
//            print("On Bottom Reached")

            self.loader.loadNext()
        }
    }

    func onTransactionClick(item: TransactionViewItem) {
        router.openTransactionInfo(viewItem: item)
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
        transactionsDiffer.reloadAll()
    }

    func onUpdate(lastBlockHeight: Int, coin: Coin) {
//        print("Last Block Height Updated: \(coin) - \(lastBlockHeight)")
        let oldLastBlockHeight = dataSource.lastBlockHeight(coin: coin)

        dataSource.set(lastBlockHeight: lastBlockHeight, coin: coin)

        if let threshold = dataSource.threshold(coin: coin), let oldLastBlockHeight = oldLastBlockHeight {
            let indexes = loader.itemIndexesForPending(coin: coin, blockHeight: oldLastBlockHeight - threshold)

            if !indexes.isEmpty {
                transactionsDiffer.reload(indexes: indexes)
            }
        }
    }

    func didUpdate(records: [TransactionRecord], coin: Coin) {
        loader.didUpdate(records: records, coin: coin)
    }

    func didFetch(rateValue: Decimal, coin: Coin, currency: Currency, date: Date) {
        dataSource.set(rate: CurrencyValue(currency: currency, value: rateValue), coin: coin, date: date)

        let indexes = loader.itemIndexes(coin: coin, date: date)

        if !indexes.isEmpty {
            transactionsDiffer.reload(indexes: indexes)
        }
    }

    func didFetch(recordsData: [Coin: [TransactionRecord]]) {
//        print("Did Fetch Records: \(recordsData.map { key, value -> String in "\(key) - \(value.count)" })")

        loader.didFetch(recordsData: recordsData)
    }

    func onConnectionRestore() {
        transactionsDiffer.reloadAll()
    }

}
