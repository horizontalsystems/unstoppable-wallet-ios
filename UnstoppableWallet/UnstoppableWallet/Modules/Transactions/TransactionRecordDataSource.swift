import Foundation
import CurrencyKit
import CoinKit

class TransactionRecordDataSource {
    private let poolRepo: TransactionRecordPoolRepo
    private let itemsDataSource: TransactionViewItemDataSource
    private let metaDataSource: TransactionsMetadataDataSource
    private let factory: TransactionViewItemFactory
    private let limit: Int

    init(poolRepo: TransactionRecordPoolRepo, itemsDataSource: TransactionViewItemDataSource,
         metaDataSource: TransactionsMetadataDataSource, factory: TransactionViewItemFactory, limit: Int = 10) {
        self.poolRepo = poolRepo
        self.itemsDataSource = itemsDataSource
        self.metaDataSource = metaDataSource
        self.factory = factory
        self.limit = limit
    }

    var items: [TransactionViewItem] {
        itemsDataSource.items
    }

    var allShown: Bool {
        for pool in poolRepo.activePools {
            if !pool.allShown {
                return false
            }
        }

        return true
    }

    var allRecordsData: [Wallet: [TransactionRecord]] {
        var recordsData = [Wallet: [TransactionRecord]]()

        for pool in poolRepo.allPools {
            recordsData[pool.wallet] = pool.records
        }

        return recordsData
    }

    private func createViewItem(for wallet: Wallet, record: TransactionRecord) -> TransactionViewItem {
        let lastBlockInfo = metaDataSource.lastBlockInfo(wallet: wallet)
        let rate = metaDataSource.rate(coin: wallet.coin, date: record.date)
        return factory.viewItem(fromRecord: record, wallet: wallet, lastBlockInfo: lastBlockInfo, rate: rate)
    }

    var fetchDataList: [FetchData] {
        poolRepo.activePools.compactMap { pool in
            pool.getFetchData(limit: limit)
        }
    }

    func handleNext(recordsData: [Wallet: [TransactionRecord]]) {
        recordsData.forEach { wallet, records in
            poolRepo.pool(byWallet: wallet)?.add(records: records)
        }
    }

    func handleUpdated(records: [TransactionRecord], wallet: Wallet) -> [TransactionViewItem]? {
        guard let pool = poolRepo.pool(byWallet: wallet) else {
            return nil
        }
        var handledItems = [TransactionRecord]()

        for record in records.sorted() {
            switch pool.handleUpdated(record: record) {
            case .updated: handledItems.append(record)
            case .inserted: handledItems.append(record)
            case .newData:
                if itemsDataSource.shouldInsert(record: record) {
                    handledItems.append(record)
                    pool.increaseFirstUnusedIndex()
                }
            case .ignored: ()
            }
        }

        guard poolRepo.isPoolActive(wallet: wallet) else {
            return nil
        }

        let items = handledItems.map { createViewItem(for: wallet, record: $0) }
        return itemsDataSource.handle(newItems: items)
    }

    func increasePage() -> Bool {
        var unusedItems = [TransactionViewItem]()

        poolRepo.activePools.forEach { pool in
            pool.unusedRecords.forEach { record in
                unusedItems.append(createViewItem(for: pool.wallet, record: record))
            }
        }

        guard !unusedItems.isEmpty else {
            return false
        }

        unusedItems.sort()
        unusedItems.reverse()

        let usedItems = Array(unusedItems.prefix(limit))

        itemsDataSource.add(items: usedItems)

        usedItems.forEach { item in
            poolRepo.pool(byWallet: item.wallet)?.increaseFirstUnusedIndex()
        }

        return true
    }

    func set(wallets: [Wallet]) {
        poolRepo.allPools.forEach { pool in
            pool.resetFirstUnusedIndex()
        }

        poolRepo.activatePools(wallets: wallets)
        itemsDataSource.clear()
    }

    func handleUpdated(wallets: [Wallet]) {
        poolRepo.deactivateAllPools()
        set(wallets: wallets)
    }

    func handleUpdated(walletsData: [(Wallet, LastBlockInfo?)]) {
        walletsData.forEach { set(lastBlockInfo: $1, wallet: $0) }
    }

    func clearRates() {
        metaDataSource.clearRates()

        for (index, item) in itemsDataSource.items.enumerated() {
            let rate = metaDataSource.rate(coin: item.wallet.coin, date: item.record.date)
            itemsDataSource.items[index].currencyValue = rate.map {
                CurrencyValue(currency: $0.currency, value: $0.value * item.record.amount)
            }
        }
    }

    @discardableResult func set(lastBlockInfo: LastBlockInfo?, wallet: Wallet) -> Bool {
        guard let lastBlockInfo = lastBlockInfo else {
            return false
        }

        let oldLastBlockInfo = metaDataSource.lastBlockInfo(wallet: wallet)
        metaDataSource.set(lastBlockInfo: lastBlockInfo, wallet: wallet)

        var itemsChanged = false

        for (index, item) in itemsDataSource.items.enumerated() {
            guard item.wallet == wallet else {
                continue
            }

            if item.becomesUnlocked(oldTimestamp: oldLastBlockInfo?.timestamp, newTimestamp: lastBlockInfo.timestamp) || item.isPending {
                itemsDataSource.items[index] = createViewItem(for: item.wallet, record: item.record)
                itemsChanged = true
            }
        }

        return itemsChanged
    }

    func set(rate: CurrencyValue, coin: Coin, date: Date) -> Bool {
        metaDataSource.set(rate: rate, coin: coin, date: date)

        var itemsChanged = false

        for (index, item) in itemsDataSource.items.enumerated() {
            if item.wallet.coin == coin && item.record.date == date {
                itemsDataSource.items[index].currencyValue = CurrencyValue(currency: rate.currency, value: rate.value * item.record.amount)
                itemsChanged = true
            }
        }

        return itemsChanged
    }
}
