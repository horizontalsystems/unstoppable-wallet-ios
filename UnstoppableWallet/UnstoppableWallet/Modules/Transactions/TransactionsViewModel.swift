import Foundation
import RxSwift
import RxCocoa

class TransactionsViewModel {
    private let disposeBag = DisposeBag()

    private let service: TransactionsService
    private let factory: TransactionsViewItemFactory

    private var sectionViewItems = [SectionViewItem]()

    private var typeFiltersRelay = BehaviorRelay<(filters: [FilterHeaderView.ViewItem], selected: Int)>(value: (filters: [], selected: 0))
    private var coinFiltersRelay = BehaviorRelay<(filters: [MarketDiscoveryFilterHeaderView.ViewItem], selected: Int?)>(value: (filters: [], selected: nil))
    private var sectionViewItemsRelay = BehaviorRelay<[SectionViewItem]>(value: [])
    private var updatedViewItemRelay = PublishRelay<(sectionIndex: Int, rowIndex: Int, item: ViewItem)>()
    private var viewStatusRelay = BehaviorRelay<TransactionsModule.ViewStatus>(value: TransactionsModule.ViewStatus(showProgress: false, messageType: nil))

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
        subscribe(disposeBag, service.syncingObservable) { [weak self] in self?.handle(syncing: $0) }

        handle(typesFilters: service.typeFilters)
        handle(walletFilters: service.walletFilters)
        handle(items: service.allItems)
        handle(syncing: service.syncing)
    }

    private func handle(typesFilters: (types: [TransactionTypeFilter], selected: Int)) {
        let filterItems = factory.typeFilterItems(types: typesFilters.types)
        typeFiltersRelay.accept((filters: filterItems, selected: typesFilters.selected))
    }

    private func handle(walletFilters: (wallets: [TransactionWallet], selected: Int?)) {
        let coinFilters = walletFilters.wallets.compactMap { factory.coinFilter(wallet: $0) }
        coinFiltersRelay.accept((filters: coinFilters, selected: walletFilters.selected))
    }

    private func handle(items: [TransactionsService.Item]) {
        let viewItems = items.map { factory.viewItem(item: $0) }
        let sectionViewItems = sectionViewItems(viewItems: viewItems)
        let showEmptyMessage = sectionViewItems.isEmpty != self.sectionViewItems.isEmpty

        self.sectionViewItems = sectionViewItems
        sectionViewItemsRelay.accept(sectionViewItems)

        if showEmptyMessage {
            handle(syncing: service.syncing)
        }
    }

    private func handle(updatedItem: TransactionsService.Item) {
        for (sectionIndex, section) in sectionViewItems.enumerated() {
            if let rowIndex = section.viewItems.firstIndex(where: { item in item.uid == updatedItem.record.uid }) {
                let viewItem = factory.viewItem(item: updatedItem)

                sectionViewItems[sectionIndex].viewItems[rowIndex] = viewItem
                updatedViewItemRelay.accept((sectionIndex: sectionIndex, rowIndex: rowIndex, item: viewItem))
            }
        }
    }

    private func handle(syncing: Bool) {
        viewStatusRelay.accept(TransactionsModule.ViewStatus(showProgress: syncing, messageType: sectionViewItems.isEmpty ? (syncing ? .syncing : .empty) : nil))
    }

    private func sectionViewItems(viewItems: [ViewItem]) -> [SectionViewItem] {
        var sectionViewItems = [SectionViewItem]()
        var lastDaysAgo = -1

        for viewItem in viewItems {
            let daysAgo = daysFrom(date: viewItem.date)

            if daysAgo != lastDaysAgo {
                sectionViewItems.append(SectionViewItem(title: dateHeaderTitle(daysAgo: daysAgo).uppercased(), viewItems: [viewItem]))
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

    var typeFiltersDriver: Driver<(filters: [FilterHeaderView.ViewItem], selected: Int)> {
        typeFiltersRelay.asDriver()
    }

    var coinFiltersDriver: Driver<(filters: [MarketDiscoveryFilterHeaderView.ViewItem], selected: Int?)> {
        coinFiltersRelay.asDriver()
    }

    var sectionViewItemsDriver: Driver<[SectionViewItem]> {
        sectionViewItemsRelay.asDriver()
    }

    var updatedViewItemSignal: Signal<(sectionIndex: Int, rowIndex: Int, item: TransactionsViewModel.ViewItem)> {
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
        let count = sectionViewItems.reduce(0) { $0 + $1.viewItems.count }
        service.load(count: count + TransactionsModule.pageLimit)
    }

    func transactionItem(uid: String) -> TransactionsService.Item? {
        service.item(uid: uid)
    }

}

extension TransactionsViewModel {

    struct SectionViewItem {
        let title: String
        var viewItems: [ViewItem]
    }

    struct ViewItem {
        let uid: String
        let date: Date
        let iconType: IconType
        let progress: Float?
        let blockchainImageName: String?
        let title: String
        let subTitle: String
        let primaryValue: Value?
        let secondaryValue: Value?
        let sentToSelf: Bool
        let locked: Bool?
    }

    enum IconType {
        case icon(imageUrl: String?, placeholderImageName: String)
        case doubleIcon(frontImageUrl: String?, frontPlaceholderImageName: String, backImageUrl: String?, backPlaceholderImageName: String)
        case localIcon(imageName: String?)
        case failedIcon
    }

    struct Value {
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
