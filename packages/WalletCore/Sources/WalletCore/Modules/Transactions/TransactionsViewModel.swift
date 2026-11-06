import Combine
import Foundation
import RxSwift

class TransactionsViewModel: ObservableObject {
    private static let pageLimit = 20

    private let walletManager = Core.shared.walletManager
    private let adapterManager = Core.shared.transactionAdapterManager
    private let reachabilityManager = Core.shared.reachabilityManager
    private let balanceHiddenManager = Core.shared.balanceHiddenManager
    private let amountRoundingManager = Core.shared.amountRoundingManager
    private let securityManger = Core.shared.securityManager
    private let contactBookManager = Core.shared.contactManager
    private let contactLabelService = TransactionsContactLabelService(contactManager: Core.shared.contactManager)
    private let rateService = HistoricalRateService(marketKit: Core.shared.marketKit, currencyManager: Core.shared.currencyManager)
    private let viewItemFactory: TransactionsViewItemFactory
    private let poolGroupFactory = PoolGroupFactory()

    private let disposeBag = DisposeBag()
    private var __poolGroupDisposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var syncing: Bool = false
    @Published private(set) var isReachable: Bool = true
    @Published private(set) var sections: [Section] = []
    /// false until the first page is published, so the view does not show the empty placeholder while loading
    @Published private(set) var isLoaded = false

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

    @Published var spamFilterEnabled: Bool {
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

    /// set after `__sections`, so on main the first page is published before `isLoaded` turns true
    private var __isLoaded = false {
        didSet {
            guard __isLoaded != oldValue else {
                return
            }

            DispatchQueue.main.async { [__isLoaded] in
                self.isLoaded = __isLoaded
            }
        }
    }

    private var __syncing: Bool = false {
        didSet {
            guard __syncing != oldValue else {
                return
            }

            DispatchQueue.main.async { [__syncing] in
                self.syncing = __syncing
            }
        }
    }

    private var __items = [Item]()
    private var __poolGroup = PoolGroup(pools: [])
    private var __lastRequestedCount = TransactionsViewModel.pageLimit
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
        isReachable = reachabilityManager.isReachable
        spamFilterEnabled = securityManger.spamFilterEnabled

        viewItemFactory = TransactionsViewItemFactory(contactLabelService: contactLabelService)

        adapterManager.adaptersReadyPublisher
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self] _ in
                self?.syncPoolGroup()
            }
            .store(in: &cancellables)
        subscribe(disposeBag, rateService.ratesChangedObservable) { [weak self] in self?.handleRatesChanged() }
        subscribe(disposeBag, rateService.rateUpdatedObservable) { [weak self] in self?.handle(rate: $0) }
        contactLabelService.statePublisher
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self] _ in self?.reportItemData() }
            .store(in: &cancellables)
        contactBookManager.addressesAddedPublisher
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self] _ in self?.syncPoolGroup() }
            .store(in: &cancellables)
        subscribe(disposeBag, balanceHiddenManager.balanceHiddenObservable) { [weak self] _ in self?.reportItemData() }

        amountRoundingManager
            .amountRoundingPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.reportItemData() }
            .store(in: &cancellables)

        reachabilityManager.$isReachable
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.isReachable = $0 }
            .store(in: &cancellables)

        securityManger.$spamFilterEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.spamFilterEnabled = $0 }
            .store(in: &cancellables)

        __syncPoolGroup()
    }

    // Queue protected methods

    private func __syncPoolGroup() {
        __poolGroup = poolGroupFactory.poolGroup(type: poolGroupType, filter: typeFilter, contact: transactionFilter.contact, scamFilterEnabled: spamFilterEnabled)
        __initPoolGroup()
    }

    private func __syncSyncing() {
        __syncing = __loading || __poolGroupSyncing
    }

    private func __initPoolGroup() {
        __poolGroupDisposeBag = DisposeBag()

        // not reported: the new load replaces the rows, and a failed one must not show the previous filter's rows
        __items = []
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
        guard !__loading, __loadMoreRequested || __poolUpdateRequested else {
            return
        }

        __loading = true
        __poolUpdateRequested = false

        let loadingMore = __loadMoreRequested

        __poolGroup.itemsSingle(count: __lastRequestedCount)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe(onSuccess: { [weak self] transactionItems in
                self?.handle(transactionItems: transactionItems, loadedMore: loadingMore)
            }, onError: { [weak self] _ in
                self?.handleLoadError()
            })
            .disposed(by: __poolGroupDisposeBag)
    }

    private func __reportItemData() {
        let viewItems = __items.map { viewItemFactory.viewItem(item: $0, balanceHidden: balanceHiddenManager.balanceHidden) }
        __sections = sectionViewItems(viewItems: viewItems)
    }

    /// Rebuilds the rows of `items` in a copy of the sections and publishes it once
    private func __reportItems(_ items: [Item]) {
        guard !items.isEmpty else {
            return
        }

        var sections = __sections
        var replaced = false

        for item in items {
            for (sectionIndex, section) in sections.enumerated() {
                if let rowIndex = section.viewItems.firstIndex(where: { $0.id == item.viewItemId }) {
                    sections[sectionIndex].viewItems[rowIndex] = viewItemFactory.viewItem(item: item, balanceHidden: balanceHiddenManager.balanceHidden)
                    replaced = true
                    break
                }
            }
        }

        // publish only when a row changed
        if replaced {
            __sections = sections
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
        guard index > __items.count - 5, !__loadMoreRequested, __lastRequestedCount == __items.count else {
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

    private func handleLoadError() {
        queue.async {
            // __load() is deliberately not called again: a failing adapter would retry in a loop; the next pool update retries
            self.__loading = false
            self.__reportItemData()
            self.__isLoaded = true
        }
    }

    private func handle(transactionItems: [TransactionItem], loadedMore: Bool) {
        queue.async {
            self.__items = transactionItems.map { transactionItem in
                Item(
                    transactionItem: transactionItem,
                    currencyValue: self.currencyValue(record: transactionItem.record, rate: self.rate(record: transactionItem.record))
                )
            }

            self.__reportItemData()
            self.__isLoaded = true

            if loadedMore {
                self.__loadMoreRequested = false
            }

            self.__loading = false
            self.__load()
        }
    }

    private func handleUpdated(transactionItems: [TransactionItem]) {
        queue.async {
            var updatedItems = [Item]()

            for transactionItem in transactionItems {
                // by source and uid: the same transaction can reach the list from two sources
                let viewItemId = Self.viewItemId(record: transactionItem.record)

                for item in self.__items {
                    if item.viewItemId == viewItemId {
                        item.transactionItem = transactionItem
                        item.currencyValue = self.currencyValue(record: transactionItem.record, rate: self.rate(record: transactionItem.record))
                        updatedItems.append(item)
                        break
                    }
                }
            }

            self.__reportItems(updatedItems)
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
            // every row of the coin and day still without fiat takes the rate; the rows are published together
            var updatedItems = [Item]()

            for item in self.__items where item.currencyValue == nil {
                if let rateKey = self.rateKey(record: item.record), rateKey == rate.0 {
                    item.currencyValue = self.currencyValue(record: item.record, rate: rate.1)
                    updatedItems.append(item)
                }
            }

            self.__reportItems(updatedItems)
        }
    }

    // Helper methods

    private var poolGroupType: PoolGroupFactory.PoolGroupType {
        if let token = transactionFilter.token {
            return .tokens(tokens: [token])
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

    private func sectionViewItems(viewItems: [ViewItem]) -> [Section] {
        var sectionViewItems = [Section]()
        // nil before the first row: a row dated after today (-1 days ago) still opens a section
        var lastDaysAgo: Int?

        for viewItem in viewItems {
            let daysAgo = daysFrom(date: viewItem.date)

            if daysAgo != lastDaysAgo {
                sectionViewItems.append(Section(id: viewItem.date, title: dateHeaderTitle(daysAgo: daysAgo), viewItems: [viewItem]))
            } else {
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

extension TransactionsViewModel {
    var filterChanged: Bool {
        transactionFilter.hasChanges || !spamFilterEnabled
    }

    var transactionListStatus: TransactionListStatus {
        if sections.isEmpty {
            if !isReachable {
                return .notReachable
            }

            return syncing ? .loading : .empty
        } else {
            return .show
        }
    }

    func record(id: String) -> TransactionRecord? {
        queue.sync {
            __items.first(where: { $0.viewItemId == id })?.record
        }
    }

    /// Finds the row by its id across every section, so a row whose section moved still loads more and fetches its rate
    func onDisplay(viewItem: ViewItem) {
        queue.async {
            var offset = 0

            for section in self.__sections {
                if let index = section.viewItems.firstIndex(where: { $0.id == viewItem.id }) {
                    self.__loadMoreIfRequired(index: offset + index)
                    self.__fetchRate(index: offset + index)
                    return
                }

                offset += section.viewItems.count
            }
        }
    }
}

extension TransactionsViewModel {
    class Item {
        var transactionItem: TransactionItem
        var currencyValue: CurrencyValue?
        /// `viewItemId(record:)`, made once: later updates keep the record's source and uid
        let viewItemId: String

        var record: TransactionRecord {
            transactionItem.record
        }

        init(transactionItem: TransactionItem, currencyValue: CurrencyValue?) {
            self.transactionItem = transactionItem
            self.currencyValue = currencyValue
            viewItemId = TransactionsViewModel.viewItemId(record: transactionItem.record)
        }
    }

    struct Section: Identifiable, Equatable {
        let id: Date
        let title: String
        var viewItems: [ViewItem]
    }

    /// Unique within the list: one transaction can reach it from two sources of a blockchain, such as
    /// a transfer between two Bitcoin derivations of a wallet, with the same `uid` in each
    static func viewItemId(record: TransactionRecord) -> String {
        "\(record.source.blockchainType.uid)|\(record.source.meta ?? "")|\(record.uid)"
    }

    struct ViewItem: Identifiable, Equatable {
        /// `viewItemId(record:)`: the row's identity and the key `record(id:)` looks it up by
        let id: String
        /// the record's own uid, which the row's test tag is made from
        let uid: String
        let date: Date
        let cell: ActivityCellViewItem
    }
}

struct TransactionListStatus: Equatable {
    let id: String
    let icon: String?
    let title: String?
    let subtitle: String?

    init(id: String, icon: String? = nil, title: String? = nil, subtitle: String? = nil) {
        self.id = id
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
    }

    static let show = TransactionListStatus(
        id: "show"
    )

    static let loading = TransactionListStatus(
        id: "loading",
        icon: "warning_filled",
        title: nil,
        subtitle: "transactions.syncing_placeholder".localized
    )

    static let empty = TransactionListStatus(
        id: "empty",
        icon: "warning_filled",
        title: nil,
        subtitle: "transactions.empty_text".localized
    )

    static let notReachable = TransactionListStatus(
        id: "not_reachable",
        icon: "globe_error",
        title: nil,
        subtitle: "alert.no_internet".localized
    )
}
