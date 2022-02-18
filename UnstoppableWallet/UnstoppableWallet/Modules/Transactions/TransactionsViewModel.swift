import Foundation
import RxSwift
import RxCocoa

class TransactionsViewModel {
    let disposeBag = DisposeBag()

    let service: TransactionsService
    let factory: TransactionsViewItemFactory

    private var sections = [TransactionsViewController.Section]()

    private var typeFiltersRelay = BehaviorRelay<(filters: [FilterHeaderView.ViewItem], selected: Int)>(value: (filters: [], selected: 0))
    private var coinFiltersRelay = BehaviorRelay<(filters: [MarketDiscoveryFilterHeaderView.ViewItem], selected: Int?)>(value: (filters: [], selected: nil))
    private var viewItemsRelay = BehaviorRelay<[TransactionsViewController.Section]>(value: [])
    private var updatedViewItemRelay = PublishRelay<(sectionIndex: Int, rowIndex: Int, item: TransactionViewItem)>()
    private var viewStatusRelay = BehaviorRelay<TransactionsModule.ViewStatus>(value: TransactionsModule.ViewStatus(showProgress: false, showMessage: false))

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.transactions_view_model", qos: .userInitiated)

    init(service: TransactionsService, factory: TransactionsViewItemFactory) {
        self.service = service
        self.factory = factory

        subscribe(disposeBag, service.typeFiltersObservable) { [weak self] typeFilters in self?.handle(typesFilters: typeFilters) }
        subscribe(disposeBag, service.walletFiltersObservable) { [weak self] walletFilters in self?.handle(walletFilters: walletFilters) }
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
        subscribe(disposeBag, service.syncStateSignal) { [weak self] syncState in self?.handle(syncState: syncState) }

        handle(typesFilters: service.typeFilters)
        handle(walletFilters: service.walletFilters)
        handle(items: service.allItems)
        handle(syncState: service.syncState)
    }

    private func handle(typesFilters: (types: [TransactionTypeFilter], selected: Int)) {
        let filterItems = factory.typeFilterItems(types: typesFilters.types)
        typeFiltersRelay.accept((filters: filterItems, selected: typesFilters.selected))
    }

    private func handle(walletFilters: (wallets: [TransactionWallet], selected: Int?)) {
        let coinFilters = walletFilters.wallets.compactMap { factory.coinFilter(wallet: $0) }
        coinFiltersRelay.accept((filters: coinFilters, selected: walletFilters.selected))
    }

    private func handle(items: [TransactionItem]) {
        let viewItems = items.map { factory.viewItem(item: $0) }
        let sections = sections(viewItems: viewItems)
        let showEmptyMessage = sections.isEmpty != self.sections.isEmpty

        self.sections = sections
        viewItemsRelay.accept(sections)

        if showEmptyMessage {
            handle(syncState: service.syncState)
        }
    }

    private func handle(updatedItem: TransactionItem) {
        for (sectionIndex, section) in sections.enumerated() {
            if let rowIndex = section.viewItems.firstIndex(where: { item in item.uid == updatedItem.record.uid }) {
                let viewItem = factory.viewItem(item: updatedItem)

                sections[sectionIndex].viewItems[rowIndex] = viewItem
                updatedViewItemRelay.accept((sectionIndex: sectionIndex, rowIndex: rowIndex, item: viewItem))
            }
        }
    }

    private func handle(syncState: AdapterState?) {
        guard let syncState = syncState else {
            return
        }

        switch syncState {
        case .syncing, .searchingTxs:
            viewStatusRelay.accept(TransactionsModule.ViewStatus(showProgress: true, showMessage: false))
        case .notSynced:
            viewStatusRelay.accept(TransactionsModule.ViewStatus(showProgress: false, showMessage: false))
        case .synced:
            if sections.isEmpty {
                viewStatusRelay.accept(TransactionsModule.ViewStatus(showProgress: false, showMessage: true))
            } else {
                viewStatusRelay.accept(TransactionsModule.ViewStatus(showProgress: false, showMessage: false))
            }
        }
    }

    private func sections(viewItems: [TransactionViewItem]) -> [TransactionsViewController.Section] {
        var sections = [TransactionsViewController.Section]()
        var lastDaysAgo = -1

        for viewItem in viewItems {
            let daysAgo = daysFrom(date: viewItem.date)

            if daysAgo != lastDaysAgo {
                sections.append(TransactionsViewController.Section(title: dateHeaderTitle(daysAgo: daysAgo).uppercased(), viewItems: [viewItem]))
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

    var typeFiltersDriver: Driver<(filters: [FilterHeaderView.ViewItem], selected: Int)> {
        typeFiltersRelay.asDriver()
    }

    var coinFiltersDriver: Driver<(filters: [MarketDiscoveryFilterHeaderView.ViewItem], selected: Int?)> {
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
        service.set(selectedWalletIndex: index)
    }

    func typeFilterSelected(index: Int) {
        service.set(selectedTypeIndex: index)
    }

    func bottomReached() {
        let count = sections.reduce(0) { $0 + $1.viewItems.count }
        service.load(count: count + TransactionsModule.pageLimit)
    }

    func transactionItem(uid: String) -> TransactionItem? {
        service.item(uid: uid)
    }

}
