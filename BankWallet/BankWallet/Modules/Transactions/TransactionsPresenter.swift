import RxSwift
import DeepDiff
import CurrencyKit

class TransactionsPresenter {
    private let interactor: ITransactionsInteractor
    private let router: ITransactionsRouter
    private let factory: ITransactionViewItemFactory
    private let dataSource: TransactionRecordDataSource
    private let metaDataSource: TransactionsMetadataDataSource
    private let viewItemLoader: ITransactionViewItemLoader
    private var loading = false

    weak var view: ITransactionsView?

    init(interactor: ITransactionsInteractor, router: ITransactionsRouter, factory: ITransactionViewItemFactory,
         dataSource: TransactionRecordDataSource, metaDataSource: TransactionsMetadataDataSource,
         viewItemLoader: ITransactionViewItemLoader) {
        self.interactor = interactor
        self.router = router
        self.factory = factory
        self.dataSource = dataSource
        self.metaDataSource = metaDataSource
        self.viewItemLoader = viewItemLoader
    }

    private func loadNext(initial: Bool = false) {
        guard !loading else {
            return
        }

        loading = true

        guard !dataSource.allShown else {
            if initial {
                //clear list on switch coins when data source has only one page
                viewItemLoader.reload(with: dataSource.items, animated: true)
            }

            loading = false
            return
        }

        let fetchDataList = dataSource.fetchDataList

        if fetchDataList.isEmpty {
            let newItems = dataSource.increasePage()

            if initial, newItems != nil {
                viewItemLoader.reload(with: dataSource.items, animated: true)
            } else if let newItems = newItems {
                viewItemLoader.add(items: newItems)
            }

            loading = false
        } else {
            interactor.fetchRecords(fetchDataList: fetchDataList, initial: initial)
        }
    }

}

extension TransactionsPresenter: ITransactionViewItemLoaderDelegate {

    func createViewItem(for item: TransactionItem) -> TransactionViewItem {
        let lastBlockInfo = metaDataSource.lastBlockInfo(wallet: item.wallet)
        let threshold = metaDataSource.threshold(wallet: item.wallet)
        let rate = metaDataSource.rate(coin: item.wallet.coin, date: item.record.date)
        return factory.viewItem(fromItem: item, lastBlockInfo: lastBlockInfo, threshold: threshold, rate: rate)
    }

    func reload(with diff: [Change<TransactionViewItem>], items: [TransactionViewItem], animated: Bool) {
        view?.reload(with: diff, items: items, animated: animated)
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
            self.loadNext()
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
        dataSource.set(wallets: selectedCoins)
        loadNext(initial: true)
    }

    func onUpdate(walletsData: [(Wallet, Int, LastBlockInfo?)]) {
        var wallets = [Wallet]()

        for (wallet, threshold, lastBlockInfo) in walletsData {
            wallets.append(wallet)
            metaDataSource.set(threshold: threshold, wallet: wallet)

            if let lastBlockInfo = lastBlockInfo {
                metaDataSource.set(lastBlockInfo: lastBlockInfo, wallet: wallet)
            }
        }

        interactor.fetchLastBlockHeights()

        if wallets.count < 2 {
            view?.show(filters: [])
        } else {
            view?.show(filters: [nil] + wallets.sorted { wallet, wallet2 in wallet.coin.code < wallet2.coin.code })
        }

        dataSource.handleUpdated(wallets: wallets)
        loadNext(initial: true)
    }

    func onUpdateBaseCurrency() {
        metaDataSource.clearRates()
        viewItemLoader.reloadAll()
    }

    func onUpdate(lastBlockInfo: LastBlockInfo, wallet: Wallet) {
        let oldLastBlockInfo = metaDataSource.lastBlockInfo(wallet: wallet)
        var needToReloadIndexes = [Int]()
        metaDataSource.set(lastBlockInfo: lastBlockInfo, wallet: wallet)

        if let timestamp = lastBlockInfo.timestamp {
            let indexes = dataSource.itemIndexesForLocked(wallet: wallet, blockTimestamp: timestamp, oldBlockTimestamp: oldLastBlockInfo?.timestamp)

            needToReloadIndexes.append(contentsOf: indexes)
        }

        if let threshold = metaDataSource.threshold(wallet: wallet), let oldLastBlockHeight = oldLastBlockInfo?.height {
            let indexes = dataSource.itemIndexesForPending(wallet: wallet, blockHeight: oldLastBlockHeight - threshold)

            needToReloadIndexes.append(contentsOf: indexes)
        }

        if !needToReloadIndexes.isEmpty {
            viewItemLoader.reload(indexes: needToReloadIndexes)
        }
    }

    func didUpdate(records: [TransactionRecord], wallet: Wallet) {
        if let updatedArray = dataSource.handleUpdated(records: records, wallet: wallet) {
            viewItemLoader.reload(with: updatedArray, animated: true)
        }
    }

    func didFetch(rateValue: Decimal, coin: Coin, currency: Currency, date: Date) {
        metaDataSource.set(rate: CurrencyValue(currency: currency, value: rateValue), coin: coin, date: date)

        let indexes = dataSource.itemIndexes(coin: coin, date: date)

        if !indexes.isEmpty {
            viewItemLoader.reload(indexes: indexes)
        }
    }

    func didFetch(recordsData: [Wallet: [TransactionRecord]], initial: Bool) {
        dataSource.handleNext(recordsData: recordsData)

        // called after load next or when pool has not enough items
        if let items = dataSource.increasePage() {
            if initial {
                viewItemLoader.reload(with: items, animated: true)
            } else {
                viewItemLoader.add(items: items)
            }
        } else if initial {
            viewItemLoader.reload(with: dataSource.items, animated: true)
        }

        loading = false
    }

    func onConnectionRestore() {
        viewItemLoader.reloadAll()
    }

}
