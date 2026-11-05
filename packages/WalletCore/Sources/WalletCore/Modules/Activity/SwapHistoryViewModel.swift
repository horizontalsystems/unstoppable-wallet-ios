import Combine
import Foundation
import MarketKit
import RxSwift

class SwapHistoryViewModel: ObservableObject {
    private static let pageLimit = 20

    private let manager = Core.shared.swapHistoryManager
    private let marketKit = Core.shared.marketKit
    private let accountManager = Core.shared.accountManager
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

    private func handleUpdated(swap: Swap) {
        queue.async {
            if let item = self.__items.first(where: { $0.swap.uid == swap.uid }) {
                item.swap = swap
                item.currencyValueOut = self.currencyValue(amount: swap.amountOut, token: swap.tokenOut, rate: self.rate(token: swap.tokenOut, date: swap.date))
                self.__reportItem(item: item)
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
            for item in self.__items {
                let swap = item.swap

                if rate.0 == RateKey(token: swap.tokenIn, date: swap.date) {
                    if item.currencyValueIn == nil {
                        item.currencyValueIn = self.currencyValue(amount: swap.amountIn, token: swap.tokenIn, rate: rate.1)
                        self.__reportItem(item: item)
                    }
                    break
                }

                if rate.0 == RateKey(token: swap.tokenOut, date: swap.date) {
                    if item.currencyValueOut == nil {
                        item.currencyValueOut = self.currencyValue(amount: swap.amountOut, token: swap.tokenOut, rate: rate.1)
                        self.__reportItem(item: item)
                    }
                    break
                }
            }
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

    private func __reportItem(item: Item) {
        for (sectionIndex, section) in __sections.enumerated() {
            if let rowIndex = section.viewItems.firstIndex(where: { $0.swap.uid == item.swap.uid }) {
                __sections[sectionIndex].viewItems[rowIndex] = __viewItem(item: item)
                break
            }
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
        ViewItem(
            swap: item.swap,
            amountIn: ValueFormatter.instance.formatShort(value: item.swap.amountIn),
            amountOut: ValueFormatter.instance.formatShort(value: item.swap.amountOut),
            fiatIn: item.currencyValueIn?.formattedShort,
            fiatOut: item.currencyValueOut?.formattedShort
        )
    }

    private func sectionViewItems(viewItems: [ViewItem]) -> [Section] {
        var sectionViewItems = [Section]()
        var lastDaysAgo = -1

        for viewItem in viewItems {
            let daysAgo = daysFrom(date: viewItem.swap.date)

            if daysAgo != lastDaysAgo {
                sectionViewItems.append(Section(id: viewItem.swap.date, title: dateHeaderTitle(daysAgo: daysAgo), viewItems: [viewItem]))
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

extension SwapHistoryViewModel {
    func correctedSwap(_ swap: Swap) -> Swap {
        guard AppConfig.showDevTools, Core.shared.localStorage.simulateFailSwap == .local else {
            return swap
        }

        return CoreDebugStubs.trackActionRequiredSwap(from: swap)
    }

    func onDisplay(section: Section, viewItem: ViewItem) {
        queue.async {
            guard let sectionIndex = self.__sections.firstIndex(where: { $0.id == section.id }),
                  let index = self.__sections[sectionIndex].viewItems.firstIndex(where: { $0.swap.uid == viewItem.swap.uid })
            else {
                return
            }

            var itemIndex = index

            for i in 0 ..< sectionIndex {
                itemIndex += self.__sections[i].viewItems.count
            }

            self.__loadMoreIfRequired(index: itemIndex)
            self.__fetchRate(index: itemIndex)
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
        let amountIn: String?
        let amountOut: String?
        var fiatIn: String?
        var fiatOut: String?

        var id: String {
            swap.uid
        }
    }
}
