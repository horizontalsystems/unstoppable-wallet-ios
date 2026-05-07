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

    private var __items = [Item]()
    private var __loading = false
    private var __allLoaded = false

    @Published var sections = [Section]()

    private var __sections: [Section] = [] {
        didSet {
            DispatchQueue.main.async { [__sections] in
                self.sections = __sections
            }
        }
    }

    init() {
        __load()

        subscribe(&cancellables, manager.swapUpdatePublisher) { [weak self] in self?.handleUpdated(swap: $0) }
        subscribe(disposeBag, rateService.ratesChangedObservable) { [weak self] in self?.handleRatesChanged() }
        subscribe(disposeBag, rateService.rateUpdatedObservable) { [weak self] in self?.handle(rate: $0) }
    }

    private func handleUpdated(swap: Swap) {
        queue.async {
            for item in self.__items {
                if item.swap.uid == swap.uid {
                    item.swap = swap
                    item.currencyValueOut = self.currencyValue(amount: swap.amountOut, token: swap.tokenOut, rate: self.rate(token: swap.tokenOut, date: swap.date))
                    self.__reportItem(item: item)
                    break
                }
            }
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
        guard let account = accountManager.activeAccount else {
            return
        }

        let swaps = manager.swaps(accountId: account.id, from: __items.last?.swap.date, limit: Self.pageLimit)
        let newItems = swaps.map { swap in
            Item(
                swap: swap,
                currencyValueIn: self.currencyValue(amount: swap.amountIn, token: swap.tokenIn, rate: self.rate(token: swap.tokenIn, date: swap.date)),
                currencyValueOut: self.currencyValue(amount: swap.amountOut, token: swap.tokenOut, rate: self.rate(token: swap.tokenOut, date: swap.date))
            )
        }

        __items.append(contentsOf: newItems)

        __reportItemData()

        if newItems.count < Self.pageLimit {
            __allLoaded = true
        }
    }

    private func __loadMoreIfRequired(index: Int) {
        guard !__allLoaded else {
            return
        }

        guard index > __items.count - 5 else {
            return
        }

        // print("load more: \(index) --- \(__items.count)")

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
    func refresh() {
        manager.sync()
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

            // print("display: \(sectionIndex) - \(index) --- \(itemIndex)")

            self.__loadMoreIfRequired(index: itemIndex)
            self.__fetchRate(index: itemIndex)
        }
    }
}

extension SwapHistoryViewModel {
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
