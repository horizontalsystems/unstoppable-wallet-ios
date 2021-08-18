import Foundation
import RxSwift
import RxCocoa
import CoinKit

class TransactionsViewModel {
    let disposeBag = DisposeBag()

    let service: TransactionsService
    let factory: TransactionsViewItemFactory

    private let allTypeFilters = TransactionTypeFilter.allCases
    private var sections = [TransactionsViewController.Section]()

    private var coinFiltersRelay = BehaviorRelay<[String]>(value: [])
    private var viewItemsRelay = BehaviorRelay<[TransactionsViewController.Section]>(value: [])
    private var updatedViewItemRelay = PublishRelay<(sectionIndex: Int, rowIndex: Int, item: TransactionViewItem)>()
    private var viewStatusRelay = BehaviorRelay<TransactionsModule.ViewStatus>(value: TransactionsModule.ViewStatus(showProgress: false, showMessage: false))

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.transactions_view_model", qos: .userInitiated)

    init(service: TransactionsService, factory: TransactionsViewItemFactory) {
        self.service = service
        self.factory = factory

        subscribe(disposeBag, service.walletsObservable) { [weak self] wallets in self?.handle(wallets: wallets) }
        subscribe(disposeBag, service.itemsObservable) { [weak self] items in
            self?.queue.async { [weak self] in
                self?.handle(items: items)
            }
        }
        subscribe(disposeBag, service.updatedItemObservable) { [weak self] item in
            self?.queue.async { [weak self] in
                self?.handle(updatedItem: item)
            }
        }
        subscribe(disposeBag, service.syncingSignal) { [weak self] syncing in self?.handle(syncing: syncing) }
    }

    private func handle(wallets: [TransactionWallet]) {
        let coinFilters = wallets.map { factory.coinFilterName(wallet: $0) }
        coinFiltersRelay.accept(coinFilters)
    }

    private func handle(items: [TransactionItem]) {
        let viewItems = items.map { factory.viewItem(item: $0) }

        sections = sections(viewItems: viewItems)
        viewItemsRelay.accept(sections)
    }

    private func handle(updatedItem: TransactionItem) {
        for (sectionIndex, section) in sections.enumerated() {
            if let rowIndex = section.viewItems.firstIndex { item in item.uid == updatedItem.record.uid } {
                let viewItem = factory.viewItem(item: updatedItem)

                sections[sectionIndex].viewItems[rowIndex] = viewItem
                updatedViewItemRelay.accept((sectionIndex: sectionIndex, rowIndex: rowIndex, item: viewItem))
            }
        }
    }

    private func handle(syncing: Bool) {
        if syncing {
            viewStatusRelay.accept(TransactionsModule.ViewStatus(showProgress: true, showMessage: false))
        } else if sections.isEmpty {
            viewStatusRelay.accept(TransactionsModule.ViewStatus(showProgress: false, showMessage: true))
        } else {
            viewStatusRelay.accept(TransactionsModule.ViewStatus(showProgress: false, showMessage: false))
        }
    }

    private func sections(viewItems: [TransactionViewItem]) -> [TransactionsViewController.Section] {
        var sections = [TransactionsViewController.Section]()
        var lastDaysAgo = -1

        for viewItem in viewItems {
            let daysAgo = daysFrom(date: viewItem.date)

            if daysAgo != lastDaysAgo {
                sections.append(TransactionsViewController.Section(title: dateHeaderTitle(daysAgo: daysAgo), viewItems: [viewItem]))
            } else {
                sections[sections.count - 1].viewItems.append(viewItem)
            }

            lastDaysAgo = daysAgo
        }

        return sections
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

    var typeFilters: [String] {
        allTypeFilters.map { "transactions.types.\($0.rawValue)".localized }
    }

    var coinFiltersDriver: Driver<[String]> {
        coinFiltersRelay.asDriver()
    }

    var viewItemsDriver: Driver<[TransactionsViewController.Section]> {
        viewItemsRelay.asDriver()
    }

    var updatedViewItemSignal: Signal<(sectionIndex: Int, rowIndex: Int, item: TransactionViewItem)> {
        updatedViewItemRelay.asSignal()
    }

    var viewStatusDriver: Driver<TransactionsModule.ViewStatus> {
        viewStatusRelay.asDriver()
    }

    func willShow(uid: String) {
        service.fetchRate(for: uid)
    }

    func coinFilterSelected(index: Int?) {
        service.set(selectedCoinFilterIndex: index)
    }

    func typeFilterSelected(index: Int) {
        service.set(typeFilter: allTypeFilters[index])
    }

    func bottomReached() {
        let count = sections.reduce(0) { $0 + $1.viewItems.count }
        service.load(count: count + TransactionsModule.pageLimit)
    }

    func transactionItem(uid: String) -> TransactionItem? {
        service.item(uid: uid)
    }

}
