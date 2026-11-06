import Combine
import Foundation
import MarketKit
import RxSwift

class SwapHistoryViewModel: ObservableObject {
    private static let pageLimit = 20

    private let manager = Core.shared.swapHistoryManager
    private let marketKit = Core.shared.marketKit
    private let accountManager = Core.shared.accountManager
    private let balanceHiddenManager = Core.shared.balanceHiddenManager
    private let evmLabelManager = Core.shared.evmLabelManager
    private let contactLabelService = TransactionsContactLabelService(contactManager: Core.shared.contactManager)
    private let rateService = HistoricalRateService(marketKit: Core.shared.marketKit, currencyManager: Core.shared.currencyManager)
    private let queue = DispatchQueue(label: "\(AppConfig.label).swap-history-view-model", qos: .userInitiated)
    private var cancellables = Set<AnyCancellable>()
    private let disposeBag = DisposeBag()
    private let operations: [Swap.Operation]

    private var __filter: Filter
    private var __accountId: String?
    private var __items = [Item]()
    private var __allLoaded = false

    @Published var sections = [Section]()
    /// false until the first page is published, so the view does not show the empty placeholder while loading
    @Published private(set) var isLoaded = false

    var transactionFilter: TransactionFilter {
        didSet {
            guard transactionFilter != oldValue else {
                return
            }

            reload(filter: Filter(transactionFilter: transactionFilter))
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

    init(operations: [Swap.Operation], transactionFilter: TransactionFilter = .init()) {
        self.operations = operations
        self.transactionFilter = transactionFilter
        __filter = Filter(transactionFilter: transactionFilter)

        // set up before the first load is queued, so no change to what it reads (balance hidden, contacts) is missed once it starts
        subscribe(disposeBag, balanceHiddenManager.balanceHiddenObservable) { [weak self] _ in self?.reportItemData() }

        // a recipient added to or renamed in the contact book shows under its new name;
        // `dropFirst` skips the replayed current state, which the load reads anyway
        contactLabelService.statePublisher
            .dropFirst()
            .receive(on: queue)
            .sink { [weak self] _ in self?.__reportItemData() }
            .store(in: &cancellables)

        queue.async {
            self.__reload()
        }

        subscribe(&cancellables, manager.swapUpdatePublisher) { [weak self] in self?.handleUpdated(swap: $0) }

        accountManager.activeAccountPublisher
            .map { $0?.id }
            .removeDuplicates()
            .receive(on: queue)
            .sink { [weak self] _ in self?.__handleActiveAccountChanged() }
            .store(in: &cancellables)

        subscribe(disposeBag, rateService.ratesChangedObservable) { [weak self] in self?.handleRatesChanged() }
        subscribe(disposeBag, rateService.rateUpdatedObservable) { [weak self] in self?.handle(rate: $0) }
    }

    private func reportItemData() {
        queue.async {
            self.__reportItemData()
        }
    }

    private func handleUpdated(swap: Swap) {
        queue.async {
            if let item = self.__items.first(where: { $0.swap.uid == swap.uid }) {
                item.swap = swap
                item.currencyValueIn = self.currencyValue(amount: swap.amountIn, token: swap.tokenIn, rate: self.rate(token: swap.tokenIn, date: swap.date))
                item.currencyValueOut = self.currencyValue(amount: swap.amountOut, token: swap.tokenOut, rate: self.rate(token: swap.tokenOut, date: swap.date))
                self.__reportItems([item])
                return
            }

            // records of another account or of other operations never enter this list
            guard swap.accountId == self.__accountId, self.operations.contains(swap.operation) else {
                return
            }

            // a swap outside the active filter never enters the list; pending swaps are re-sent on every sync tick
            guard self.__filter.matches(swap: swap) else {
                return
            }

            // a swap older than the loaded range arrives with the next page, reloading would reset the scroll
            if !self.__allLoaded, let lastDate = self.__items.last?.swap.date, swap.date < lastDate {
                return
            }

            self.__reload()
        }
    }

    private func __handleActiveAccountChanged() {
        // the list already shows this account: the first emission after init, or a switch that came back before this ran
        guard accountManager.activeAccount?.id != __accountId else {
            return
        }

        __reload()
    }

    private func reload(filter: Filter) {
        queue.async {
            self.__filter = filter
            self.__reload()
        }
    }

    private func handleRatesChanged() {
        queue.async {
            for item in self.__items {
                let swap = item.swap
                item.currencyValueIn = self.currencyValue(amount: swap.amountIn, token: swap.tokenIn, rate: self.rate(token: swap.tokenIn, date: swap.date))
                item.currencyValueOut = self.currencyValue(amount: swap.amountOut, token: swap.tokenOut, rate: self.rate(token: swap.tokenOut, date: swap.date))
            }

            self.__reportItemData()
        }
    }

    private func handle(rate: (RateKey, CurrencyValue)) {
        queue.async {
            // every swap of the coin and day takes the rate; the rows are published together
            var updatedItems = [Item]()

            for item in self.__items {
                let swap = item.swap
                var updated = false

                if rate.0 == RateKey(token: swap.tokenIn, date: swap.date), item.currencyValueIn == nil {
                    item.currencyValueIn = self.currencyValue(amount: swap.amountIn, token: swap.tokenIn, rate: rate.1)
                    updated = true
                }

                if rate.0 == RateKey(token: swap.tokenOut, date: swap.date), item.currencyValueOut == nil {
                    item.currencyValueOut = self.currencyValue(amount: swap.amountOut, token: swap.tokenOut, rate: rate.1)
                    updated = true
                }

                if updated {
                    updatedItems.append(item)
                }
            }

            self.__reportItems(updatedItems)
        }
    }

    private func __load() {
        guard let accountId = __accountId else {
            return
        }

        // the active account changed since the list was loaded: start over instead of appending another account's page
        guard accountManager.activeAccount?.id == accountId else {
            __reload()
            return
        }

        let swaps = manager.swaps(
            accountId: accountId,
            token: __filter.token,
            blockchainType: __filter.blockchainType,
            addresses: __filter.addresses,
            from: __items.last?.swap.date,
            operations: operations,
            limit: Self.pageLimit
        )
        let newItems = swaps.map { swap in
            Item(
                swap: swap,
                currencyValueIn: self.currencyValue(amount: swap.amountIn, token: swap.tokenIn, rate: self.rate(token: swap.tokenIn, date: swap.date)),
                currencyValueOut: self.currencyValue(amount: swap.amountOut, token: swap.tokenOut, rate: self.rate(token: swap.tokenOut, date: swap.date))
            )
        }

        __items.append(contentsOf: newItems)

        __reportItemData()
        __isLoaded = true

        if newItems.count < Self.pageLimit {
            __allLoaded = true
        }
    }

    private func __reload() {
        __items = []
        __allLoaded = false
        __accountId = accountManager.activeAccount?.id

        guard __accountId != nil else {
            __reportItemData()
            __isLoaded = true
            return
        }

        __load()
    }

    private func __loadMoreIfRequired(index: Int) {
        guard !__allLoaded, index > __items.count - 5 else {
            return
        }

        __load()
    }

    private func currencyValue(amount: Decimal, token _: Token, rate: CurrencyValue?) -> CurrencyValue? {
        guard let rate else {
            return nil
        }

        return CurrencyValue(currency: rate.currency, value: amount * rate.value)
    }

    private func rate(token: Token, date: Date) -> CurrencyValue? {
        rateService.rate(key: RateKey(token: token, date: date))
    }

    private func __reportItemData() {
        let viewItems = __items.map { __viewItem(item: $0) }
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
                if let rowIndex = section.viewItems.firstIndex(where: { $0.swap.uid == item.swap.uid }) {
                    sections[sectionIndex].viewItems[rowIndex] = __viewItem(item: item)
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
        let swap = item.swap

        if item.currencyValueIn == nil {
            rateService.fetchRate(key: RateKey(token: swap.tokenIn, date: swap.date))
        }

        if item.currencyValueOut == nil {
            rateService.fetchRate(key: RateKey(token: swap.tokenOut, date: swap.date))
        }
    }

    private func __viewItem(item: Item) -> ViewItem {
        let swap = item.swap
        let amountIn = ValueFormatter.instance.formatShort(value: swap.amountIn)
        let amountOut = ValueFormatter.instance.formatShort(value: swap.amountOut)
        let fiatIn = item.currencyValueIn?.formattedShort
        // the steps only give the subtitle of a pending swap
        let legs = SwapCellViewItemFactory.state(status: swap.status) == .pending ? SwapLegsBuilder.withoutUrls.legs(swap: swap) : []

        return ViewItem(
            swap: swap,
            cell: SwapCellViewItemFactory.viewItem(
                swap: swap,
                legs: legs,
                amountIn: amountIn,
                amountOut: amountOut,
                fiatIn: fiatIn,
                recipientName: recipientName(swap: swap),
                balanceHidden: balanceHiddenManager.balanceHidden
            )
        )
    }

    /// The contact name or label of the address a Private Send or CrossPay delivers to, else the shortened address
    private func recipientName(swap: Swap) -> String? {
        switch swap.operation {
        case .privateSend, .crossPay:
            let address = SwapCellViewItemFactory.recipientAddress(swap: swap)
            let blockchainType = swap.tokenOut.blockchainType
            return contactLabelService.contactData(for: address, blockchainType: blockchainType).name ?? evmLabelManager.mapped(address: address)
        case .swap, .splitSwap:
            return nil
        }
    }

    private func sectionViewItems(viewItems: [ViewItem]) -> [Section] {
        var sectionViewItems = [Section]()
        // nil before the first row: a row dated after today (-1 days ago) still opens a section
        var lastDaysAgo: Int?

        for viewItem in viewItems {
            let daysAgo = daysFrom(date: viewItem.swap.date)

            if daysAgo != lastDaysAgo {
                sectionViewItems.append(Section(id: viewItem.swap.date, title: dateHeaderTitle(daysAgo: daysAgo), viewItems: [viewItem]))
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

extension SwapHistoryViewModel {
    func correctedSwap(_ swap: Swap) -> Swap {
        guard AppConfig.showDevTools, Core.shared.localStorage.simulateFailSwap == .local else {
            return swap
        }

        return CoreDebugStubs.trackActionRequiredSwap(from: swap)
    }

    /// Finds the row by its swap across every section, so a row whose section moved still loads more and fetches its rate
    func onDisplay(viewItem: ViewItem) {
        queue.async {
            var offset = 0

            for section in self.__sections {
                if let index = section.viewItems.firstIndex(where: { $0.swap.uid == viewItem.swap.uid }) {
                    self.__loadMoreIfRequired(index: offset + index)
                    self.__fetchRate(index: offset + index)
                    return
                }

                offset += section.viewItems.count
            }
        }
    }
}

extension SwapHistoryViewModel {
    private struct Filter {
        let token: Token?
        let blockchainType: BlockchainType?
        let addresses: [String]?

        init(transactionFilter: TransactionFilter) {
            token = transactionFilter.token
            blockchainType = transactionFilter.blockchain?.type

            if let contact = transactionFilter.contact {
                let contactAddresses = blockchainType.map { type in contact.addresses.filter { $0.blockchainUid == type.uid } } ?? contact.addresses
                addresses = contactAddresses.map(\.address)
            } else {
                addresses = nil
            }
        }

        /// mirrors the token, blockchain and address conditions of `SwapStorage.swaps`
        func matches(swap: Swap) -> Bool {
            let tokenQueryIdIn = swap.tokenIn.tokenQuery.id
            let tokenQueryIdOut = swap.tokenOut.tokenQuery.id

            if let tokenQueryId = token?.tokenQuery.id {
                guard tokenQueryIdIn == tokenQueryId || tokenQueryIdOut == tokenQueryId else {
                    return false
                }
            } else if let blockchainType {
                let prefix = "\(blockchainType.uid)|"

                guard tokenQueryIdIn.hasPrefix(prefix) || tokenQueryIdOut.hasPrefix(prefix) else {
                    return false
                }
            }

            if let addresses {
                let lowercased = Set(addresses.map { $0.lowercased() })
                let swapAddresses = [swap.recipient, swap.toAddress, swap.sourceAddress].compactMap { $0?.lowercased() }

                guard swapAddresses.contains(where: { lowercased.contains($0) }) else {
                    return false
                }
            }

            return true
        }
    }

    class Item {
        var swap: Swap
        var currencyValueIn: CurrencyValue?
        var currencyValueOut: CurrencyValue?

        init(swap: Swap, currencyValueIn: CurrencyValue?, currencyValueOut: CurrencyValue?) {
            self.swap = swap
            self.currencyValueIn = currencyValueIn
            self.currencyValueOut = currencyValueOut
        }
    }

    struct Section: Identifiable {
        let id: Date
        let title: String
        var viewItems: [ViewItem]
    }

    struct ViewItem: Identifiable {
        var swap: Swap
        let cell: ActivityCellViewItem

        var id: String {
            swap.uid
        }
    }
}
