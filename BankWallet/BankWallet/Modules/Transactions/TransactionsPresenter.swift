import RxSwift
import DeepDiff
import CurrencyKit

class TransactionsPresenter {
    private let interactor: ITransactionsInteractor
    private let router: ITransactionsRouter
    private let factory: ITransactionViewItemFactory
    private let loader: TransactionsLoader
    private let dataSource: TransactionsMetadataDataSource
    private let viewItemLoader: ITransactionViewItemLoader

    weak var view: ITransactionsView?

    init(interactor: ITransactionsInteractor, router: ITransactionsRouter, factory: ITransactionViewItemFactory, loader: TransactionsLoader, dataSource: TransactionsMetadataDataSource, viewItemLoader: ITransactionViewItemLoader) {
        self.interactor = interactor
        self.router = router
        self.factory = factory
        self.loader = loader
        self.dataSource = dataSource
        self.viewItemLoader = viewItemLoader
    }

}

extension TransactionsPresenter: ITransactionViewItemLoaderDelegate {

    func createViewItem(for item: TransactionItem) -> TransactionViewItem {
        let lastBlockInfo = dataSource.lastBlockInfo(wallet: item.wallet)
        let threshold = dataSource.threshold(wallet: item.wallet)
        let rate = dataSource.rate(coin: item.wallet.coin, date: item.record.date)
        return factory.viewItem(fromItem: item, lastBlockInfo: lastBlockInfo, threshold: threshold, rate: rate)
    }

    func reload(with diff: [Change<TransactionViewItem>], items: [TransactionViewItem], animated: Bool) {
        view?.reload(with: diff, items: items, animated: animated)
    }

}

extension TransactionsPresenter: ITransactionLoaderDelegate {

    func fetchRecords(fetchDataList: [FetchData], initial: Bool) {
        interactor.fetchRecords(fetchDataList: fetchDataList, initial: initial)
    }

    func reload(with newItems: [TransactionItem], animated: Bool) {
        viewItemLoader.reload(with: newItems, animated: animated)
    }

    func add(items: [TransactionItem]) {
        viewItemLoader.add(items: items)
    }

}

extension TransactionsPresenter: ITransactionsViewDelegate {

    func viewDidLoad() {
        interactor.initialFetch()
    }

    func onFilterSelect(wallet: Wallet?) {
        let wallets = wallet.map { [$0] } ?? []
        interactor.set(selectedWallets: wallets)
    }

    func onBottomReached() {
        DispatchQueue.main.async {
            self.loader.loadNext()
        }
    }

    func onTransactionClick(item: TransactionViewItem) {
        router.openTransactionInfo(viewItem: item)
    }

    func willShow(item: TransactionViewItem) {
        if item.rate == nil {
            interactor.fetchRate(coin: item.wallet.coin, date: item.date)
        }
    }

}

extension TransactionsPresenter: ITransactionsInteractorDelegate {

    func onUpdate(selectedCoins: [Wallet]) {
        loader.set(wallets: selectedCoins)
        loader.loadNext(initial: true)
    }

    func onUpdate(walletsData: [(Wallet, Int, LastBlockInfo?)]) {
        var wallets = [Wallet]()

        for (wallet, threshold, lastBlockInfo) in walletsData {
            wallets.append(wallet)
            dataSource.set(threshold: threshold, wallet: wallet)

            if let lastBlockInfo = lastBlockInfo {
                dataSource.set(lastBlockInfo: lastBlockInfo, wallet: wallet)
            }
        }

        interactor.fetchLastBlockHeights()

        if wallets.count < 2 {
            view?.show(filters: [])
        } else {
            view?.show(filters: [nil] + wallets.sorted { wallet, wallet2 in wallet.coin.code < wallet2.coin.code })
        }

        loader.handleUpdate(wallets: wallets)
        loader.loadNext(initial: true)
    }

    func onUpdateBaseCurrency() {
        dataSource.clearRates()
        viewItemLoader.reloadAll()
    }

    func onUpdate(lastBlockInfo: LastBlockInfo, wallet: Wallet) {
        let oldLastBlockInfo = dataSource.lastBlockInfo(wallet: wallet)
        var needToReloadIndexes = [Int]()
        dataSource.set(lastBlockInfo: lastBlockInfo, wallet: wallet)

        if let timestamp = lastBlockInfo.timestamp {
            let indexes = loader.itemIndexesForLocked(wallet: wallet, blockTimestamp: timestamp, oldBlockTimestamp: oldLastBlockInfo?.timestamp)

            needToReloadIndexes.append(contentsOf: indexes)
        }

        if let threshold = dataSource.threshold(wallet: wallet), let oldLastBlockHeight = oldLastBlockInfo?.height {
            let indexes = loader.itemIndexesForPending(wallet: wallet, blockHeight: oldLastBlockHeight - threshold)

            needToReloadIndexes.append(contentsOf: indexes)
        }

        if !needToReloadIndexes.isEmpty {
            viewItemLoader.reload(indexes: needToReloadIndexes)
        }
    }

    func didUpdate(records: [TransactionRecord], wallet: Wallet) {
        loader.didUpdate(records: records, wallet: wallet)
    }

    func didFetch(rateValue: Decimal, coin: Coin, currency: Currency, date: Date) {
        dataSource.set(rate: CurrencyValue(currency: currency, value: rateValue), coin: coin, date: date)

        let indexes = loader.itemIndexes(coin: coin, date: date)

        if !indexes.isEmpty {
            viewItemLoader.reload(indexes: indexes)
        }
    }

    func didFetch(recordsData: [Wallet: [TransactionRecord]], initial: Bool) {
        loader.didFetch(recordsData: recordsData, initial: initial)
    }

    func onConnectionRestore() {
        viewItemLoader.reloadAll()
    }

}
