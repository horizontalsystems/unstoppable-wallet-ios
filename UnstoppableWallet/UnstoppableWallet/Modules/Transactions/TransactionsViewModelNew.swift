import Combine
import Foundation
import RxSwift

class TransactionsViewModelNew: ObservableObject {
    private static let pageLimit = 20

    private let walletManager = Core.shared.walletManager
    private let adapterManager = Core.shared.transactionAdapterManager
    private let balanceHiddenManager = Core.shared.balanceHiddenManager
    private let contactLabelService = TransactionsContactLabelService(contactManager: Core.shared.contactManager)
    private let rateService = HistoricalRateService(marketKit: Core.shared.marketKit, currencyManager: Core.shared.currencyManager)
    private let nftMetadataService = NftMetadataService(nftMetadataManager: Core.shared.nftMetadataManager)
    private let viewItemFactory: TransactionsViewItemFactoryNew
    private let poolGroupFactory = PoolGroupFactory()

    private let disposeBag = DisposeBag()
    private var __poolGroupDisposeBag = DisposeBag()

    @Published private(set) var syncing: Bool = false
    @Published private(set) var sections: [Section] = []

    @Published var typeFilter: TransactionTypeFilter = .all {
        didSet {
            guard typeFilter != oldValue else {
                return
            }

            syncPoolGroup()
        }
    }

    @Published var transactionFilter: TransactionFilter {
        didSet {
            syncPoolGroup()
        }
    }

    private var __sections: [Section] = [] {
        didSet {
            DispatchQueue.main.async { [__sections] in
                self.sections = __sections
            }
        }
    }

    private var __syncing: Bool = false {
        didSet {
            guard __syncing != syncing else {
                return
            }

            DispatchQueue.main.async { [__syncing] in
                self.syncing = __syncing
            }
        }
    }

    private var __items = [Item]()
    private var __poolGroup = PoolGroup(pools: [])
    private var __lastRequestedCount = TransactionsViewModelNew.pageLimit
    private var __loadMoreRequested = false
    private var __poolUpdateRequested = false

    private var __loading = false {
        didSet {
            __syncSyncing()
        }
    }

    private var __poolGroupSyncing = false {
        didSet {
            __syncSyncing()
        }
    }

    private let queue = DispatchQueue(label: "\(AppConfig.label).transactions-view-model", qos: .userInitiated)

    init(transactionFilter: TransactionFilter = .init()) {
        self.transactionFilter = transactionFilter
        viewItemFactory = TransactionsViewItemFactoryNew(contactLabelService: contactLabelService)

        subscribe(disposeBag, adapterManager.adaptersReadyObservable) { [weak self] _ in self?.syncPoolGroup() }
        subscribe(disposeBag, rateService.ratesChangedObservable) { [weak self] in self?.handleRatesChanged() }
        subscribe(disposeBag, rateService.rateUpdatedObservable) { [weak self] in self?.handle(rate: $0) }
        subscribe(disposeBag, nftMetadataService.assetsBriefMetadataObservable) { [weak self] in self?.handle(assetsBriefMetadata: $0) }
        subscribe(disposeBag, contactLabelService.stateObservable) { [weak self] _ in self?.reportItemData() }
        subscribe(disposeBag, balanceHiddenManager.balanceHiddenObservable) { [weak self] _ in self?.reportItemData() }

        __syncPoolGroup()
    }

    // Queue protected methods

    private func __syncPoolGroup() {
        __poolGroup = poolGroupFactory.poolGroup(type: poolGroupType, filter: typeFilter, contact: transactionFilter.contact, scamFilterEnabled: transactionFilter.scamFilterEnabled)
        __initPoolGroup()
    }

    private func __syncSyncing() {
        __syncing = __loading || __poolGroupSyncing
    }

    private func __initPoolGroup() {
        __poolGroupDisposeBag = DisposeBag()

        __lastRequestedCount = Self.pageLimit
        __loading = false
        __loadMoreRequested = true
        __poolUpdateRequested = false

        __load()

        __poolGroupSyncing = __poolGroup.syncing

        __poolGroup.invalidatedObservable
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe(onNext: { [weak self] in
                self?.onPoolGroupInvalidated()
            })
            .disposed(by: __poolGroupDisposeBag)

        __poolGroup.itemsUpdatedObservable
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe(onNext: { [weak self] transactionItems in
                self?.handleUpdated(transactionItems: transactionItems)
            })
            .disposed(by: __poolGroupDisposeBag)

        __poolGroup.syncingObservable
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe(onNext: { [weak self] syncing in
                self?.handleUpdated(poolGroupSyncing: syncing)
            })
            .disposed(by: __poolGroupDisposeBag)
    }

    private func __load() {
        guard !__loading else {
            return
        }

        guard __loadMoreRequested || __poolUpdateRequested else {
            return
        }

        __loading = true
        __poolUpdateRequested = false

        let loadingMore = __loadMoreRequested

        __poolGroup.itemsSingle(count: __lastRequestedCount)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe(onSuccess: { [weak self] transactionItems in
                self?.handle(transactionItems: transactionItems, loadedMore: loadingMore)
            })
            .disposed(by: __poolGroupDisposeBag)
    }

    private func __reportItemData() {
        let viewItems = __items.map { viewItemFactory.viewItem(item: $0, balanceHidden: balanceHiddenManager.balanceHidden) }
        __sections = sectionViewItems(viewItems: viewItems)
    }

    private func __reportItem(item: Item) {
        for (sectionIndex, section) in __sections.enumerated() {
            if let rowIndex = section.viewItems.firstIndex(where: { $0.id == item.record.id }) {
                let viewItem = viewItemFactory.viewItem(item: item, balanceHidden: balanceHiddenManager.balanceHidden)
                __sections[sectionIndex].viewItems[rowIndex] = viewItem
                break
            }
        }
    }

    private func __fetchRate(index: Int) {
        guard index < __items.count else {
            return
        }

        let item = __items[index]

        guard item.currencyValue == nil, let rateKey = rateKey(record: item.record) else {
            return
        }

        rateService.fetchRate(key: rateKey)
    }

    private func __loadMoreIfRequired(index: Int) {
        guard index > __items.count - 5 else {
            return
        }

        guard !__loadMoreRequested else {
            return
        }

        guard __lastRequestedCount == __items.count else {
            return
        }

        // print("load more: \(index) --- \(self.items.count)")

        __lastRequestedCount = __items.count + Self.pageLimit
        __loadMoreRequested = true
        __load()
    }

    // Regular methods

    private func syncPoolGroup() {
        queue.async {
            self.__syncPoolGroup()
        }
    }

    private func reportItemData() {
        queue.async {
            self.__reportItemData()
        }
    }

    private func onPoolGroupInvalidated() {
        queue.async {
            self.__poolUpdateRequested = true
            self.__load()
        }
    }

    private func handle(transactionItems: [TransactionItem], loadedMore: Bool) {
        queue.async {
            let nftUids = transactionItems.map(\.record).nftUids
            let nftMetadata = self.nftMetadataService.assetsBriefMetadata(nftUids: nftUids)

            let missingNftUids = nftUids.subtracting(Set(nftMetadata.keys))
            if !missingNftUids.isEmpty {
                self.nftMetadataService.fetch(nftUids: missingNftUids)
            }

            self.__items = transactionItems.map { transactionItem in
                Item(
                    transactionItem: transactionItem,
                    nftMetadata: self.nftMetadata(transactionRecord: transactionItem.record, allMetadata: nftMetadata),
                    currencyValue: self.currencyValue(record: transactionItem.record, rate: self.rate(record: transactionItem.record))
                )
            }

            self.__reportItemData()

            if loadedMore {
                self.__loadMoreRequested = false
            }

            self.__loading = false
            self.__load()
        }
    }

    private func handleUpdated(transactionItems: [TransactionItem]) {
        queue.async {
            for transactionItem in transactionItems {
                for item in self.__items {
                    if item.record == transactionItem.record {
                        item.transactionItem = transactionItem
                        item.currencyValue = self.currencyValue(record: transactionItem.record, rate: self.rate(record: transactionItem.record))
                        self.__reportItem(item: item)
                        break
                    }
                }
            }
        }
    }

    private func handleUpdated(poolGroupSyncing: Bool) {
        queue.async {
            self.__poolGroupSyncing = poolGroupSyncing
        }
    }

    private func handleRatesChanged() {
        queue.async {
            for item in self.__items {
                item.currencyValue = self.currencyValue(record: item.record, rate: self.rate(record: item.record))
            }

            self.__reportItemData()
        }
    }

    private func handle(rate: (RateKey, CurrencyValue)) {
        queue.async {
            for item in self.__items {
                if let rateKey = self.rateKey(record: item.record), rateKey == rate.0 {
                    item.currencyValue = self.currencyValue(record: item.record, rate: rate.1)
                    self.__reportItem(item: item)
                    break
                }
            }
        }
    }

    private func handle(assetsBriefMetadata: [NftUid: NftAssetBriefMetadata]) {
        queue.async {
            let fetchedNftUids = Set(assetsBriefMetadata.keys)

            for item in self.__items {
                let fetchedItemNftUids = item.transactionItem.record.nftUids.intersection(fetchedNftUids)

                guard !fetchedItemNftUids.isEmpty else {
                    continue
                }

                for nftUid in fetchedItemNftUids {
                    item.nftMetadata[nftUid] = assetsBriefMetadata[nftUid]
                }

                self.__reportItem(item: item)
            }
        }
    }

    // Helper methods

    private var poolGroupType: PoolGroupFactory.PoolGroupType {
        if let token = transactionFilter.token {
            return .token(token: token)
        } else if let blockchain = transactionFilter.blockchain {
            return .blockchain(blockchainType: blockchain.type, wallets: walletManager.activeWallets)
        } else {
            return .all(wallets: walletManager.activeWallets)
        }
    }

    private func rate(record: TransactionRecord) -> CurrencyValue? {
        guard let rateKey = rateKey(record: record) else {
            return nil
        }

        return rateService.rate(key: rateKey)
    }

    private func rateKey(record: TransactionRecord) -> RateKey? {
        guard let token = record.mainValue?.token else {
            return nil
        }

        return RateKey(token: token, date: record.date)
    }

    private func currencyValue(record: TransactionRecord, rate: CurrencyValue?) -> CurrencyValue? {
        guard let rate, let mainValue = record.mainValue else {
            return nil
        }

        return CurrencyValue(currency: rate.currency, value: mainValue.value * rate.value)
    }

    private func nftMetadata(transactionRecord: TransactionRecord, allMetadata: [NftUid: NftAssetBriefMetadata]) -> [NftUid: NftAssetBriefMetadata] {
        var metadata = [NftUid: NftAssetBriefMetadata]()
        for nftUid in transactionRecord.nftUids {
            if let item = allMetadata[nftUid] {
                metadata[nftUid] = item
            }
        }
        return metadata
    }

    private func sectionViewItems(viewItems: [ViewItem]) -> [Section] {
        var sectionViewItems = [Section]()
        var lastDaysAgo = -1

        for viewItem in viewItems {
            let daysAgo = daysFrom(date: viewItem.date)

            if daysAgo != lastDaysAgo {
                sectionViewItems.append(Section(id: viewItem.date, title: dateHeaderTitle(daysAgo: daysAgo), viewItems: [viewItem]))
            } else if !sectionViewItems.isEmpty {
                sectionViewItems[sectionViewItems.count - 1].viewItems.append(viewItem)
            }

            lastDaysAgo = daysAgo
        }

        return sectionViewItems
    }

    private func daysFrom(date: Date) -> Int {
        let calendar = Calendar.current
        let startOfNow = calendar.startOfDay(for: Date())
        let startOfDate = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.day], from: startOfDate, to: startOfNow)

        return components.day ?? 0
    }

    private func dateHeaderTitle(daysAgo: Int) -> String {
        if daysAgo == 0 {
            return "transactions.today".localized
        } else if daysAgo == 1 {
            return "transactions.yesterday".localized
        } else {
            let date = Date(timeIntervalSince1970: Date().timeIntervalSince1970 - Double(daysAgo * 60 * 60 * 24))
            return DateHelper.instance.formatTransactionDate(from: date)
        }
    }
}

extension TransactionsViewModelNew {
    func record(id: String) -> TransactionRecord? {
        queue.sync {
            __items.first(where: { $0.record.uid == id })?.record
        }
    }

    func onTap(section: Section, viewItem: ViewItem) {
        queue.async {
            guard let sectionIndex = self.__sections.firstIndex(where: { $0.id == section.id }), let index = self.__sections[sectionIndex].viewItems.firstIndex(where: { $0.id == viewItem.id }) else {
                return
            }

            self.__sections[sectionIndex].viewItems[index].title += "1"
            // self.__sections[sectionIndex].viewItems[index].progress = (self.__sections[sectionIndex].viewItems[index].progress ?? 0.0) + 0.1

            // var newViewItem = self.__sections[sectionIndex].viewItems[index]
            // newViewItem.id = UUID().description

            // self.__sections[sectionIndex].viewItems.append(newViewItem)
        }
    }

    func onDisplay(section: Section, viewItem: ViewItem) {
        queue.async {
            guard let sectionIndex = self.__sections.firstIndex(where: { $0.id == section.id }),
                  let index = self.__sections[sectionIndex].viewItems.firstIndex(where: { $0.id == viewItem.id })
            else {
                return
            }

            var itemIndex = index

            for i in 0 ..< sectionIndex {
                itemIndex += self.__sections[i].viewItems.count
            }

            // print("ON DISPLAY: \(sectionIndex) - \(index) --- \(itemIndex)")

            self.__loadMoreIfRequired(index: itemIndex)
            self.__fetchRate(index: itemIndex)
        }
    }
}

extension TransactionsViewModelNew {
    class Item {
        var transactionItem: TransactionItem
        var nftMetadata: [NftUid: NftAssetBriefMetadata]
        var currencyValue: CurrencyValue?

        var record: TransactionRecord {
            transactionItem.record
        }

        init(transactionItem: TransactionItem, nftMetadata: [NftUid: NftAssetBriefMetadata], currencyValue: CurrencyValue?) {
            self.transactionItem = transactionItem
            self.nftMetadata = nftMetadata
            self.currencyValue = currencyValue
        }
    }

    struct Section: Identifiable, Equatable {
        let id: Date
        let title: String
        var viewItems: [ViewItem]
    }

    struct ViewItem: Identifiable, Equatable {
        var id: String
        let date: Date
        let iconType: IconType
        var progress: Float?
        var title: String
        let subTitle: String
        let primaryValue: Value?
        let secondaryValue: Value?
        let doubleSpend: Bool
        let sentToSelf: Bool
        let locked: Bool?
        let spam: Bool
    }

    enum IconType: Equatable {
        case icon(url: String?, alternativeUrl: String?, placeholderImageName: String, type: IconView.IconType)
        case doubleIcon(frontType: IconView.IconType, frontUrl: String?, frontAlternativeUrl: String?, frontPlaceholder: String, backType: IconView.IconType, backUrl: String?, backAlternativeUrl: String?, backPlaceholder: String)
        case localIcon(imageName: String?)
        case failedIcon
    }

    struct Value: Equatable {
        let text: String
        let type: ValueType
    }

    enum ValueType {
        case incoming
        case outgoing
        case neutral
        case secondary
    }
}
