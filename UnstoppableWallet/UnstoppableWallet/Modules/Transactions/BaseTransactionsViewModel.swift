import Foundation
import RxSwift
import RxCocoa
import MarketKit
import ComponentKit

class BaseTransactionsViewModel {
    private let service: BaseTransactionsService
    private let contactLabelService: TransactionsContactLabelService
    private let factory: TransactionsViewItemFactory
    private let disposeBag = DisposeBag()

    private let typeFilterIndexRelay = BehaviorRelay<Int>(value: 0)

    private let viewDataRelay = BehaviorRelay<ViewData>(value: ViewData(sectionViewItems: [], allLoaded: true, updateInfo: nil))
    private var syncingRelay = BehaviorRelay<Bool>(value: false)
    private var resetEnabledRelay = BehaviorRelay<Bool>(value: false)

    private var sectionViewItems = [SectionViewItem]()

    private let queue = DispatchQueue(label: "\(AppConfig.label).base_transactions_view_model", qos: .userInitiated)

    init(service: BaseTransactionsService, contactLabelService: TransactionsContactLabelService, factory: TransactionsViewItemFactory) {
        self.service = service
        self.factory = factory
        self.contactLabelService = contactLabelService

        subscribe(disposeBag, service.typeFilterObservable) { [weak self] in self?.sync(typeFilter: $0) }
        subscribe(disposeBag, service.itemDataObservable) { [weak self] in self?.sync(itemData: $0) }
        subscribe(disposeBag, service.itemUpdatedObservable) { [weak self] in self?.syncUpdated(item: $0) }
        subscribe(disposeBag, service.syncingObservable) { [weak self] in self?.sync(syncing: $0) }
        subscribe(disposeBag, service.canResetObservable) { [weak self] in self?.sync(canReset: $0) }
        subscribe(disposeBag, contactLabelService.stateObservable) { [weak self] _ in self?.reSyncViewItems() }
        subscribe(disposeBag, service.balanceHiddenObservable) { [weak self] _ in self?.reSyncViewItems() }

        _sync(itemData: service.itemData)
        _sync(syncing: service.syncing)
        sync(canReset: service.canReset)
    }

    private func reSyncViewItems() {
        _sync(itemData: service.itemData)
    }

    private func sync(canReset: Bool) {
        resetEnabledRelay.accept(canReset)
    }

    private func sync(typeFilter: TransactionTypeFilter) {
        guard let index = TransactionTypeFilter.allCases.firstIndex(of: typeFilter) else {
            return
        }

        typeFilterIndexRelay.accept(index)
    }

    private func sync(itemData: TransactionsService.ItemData) {
        queue.async {
            self._sync(itemData: itemData)
        }
    }

    private func _sync(itemData: TransactionsService.ItemData) {
        let viewItems = itemData.items.map { factory.viewItem(item: $0, balanceHidden: service.balanceHidden) }
        sectionViewItems = sectionViewItems(viewItems: viewItems)

        _reportViewData(allLoaded: itemData.allLoaded)
        _sync(syncing: service.syncing)
    }

    private func syncUpdated(item: TransactionsService.Item) {
        queue.async {
            self._syncUpdated(item: item)
        }
    }

    private func _syncUpdated(item: TransactionsService.Item) {
        for (sectionIndex, section) in sectionViewItems.enumerated() {
            if let rowIndex = section.viewItems.firstIndex(where: { $0.uid == item.record.uid }) {
                let viewItem = factory.viewItem(item: item, balanceHidden: service.balanceHidden)
                sectionViewItems[sectionIndex].viewItems[rowIndex] = viewItem
                _reportViewData(updateInfo: UpdateInfo(sectionIndex: sectionIndex, index: rowIndex))
            }
        }
    }

    private func _reportViewData(allLoaded: Bool? = nil, updateInfo: UpdateInfo? = nil) {
        let viewData = ViewData(sectionViewItems: sectionViewItems, allLoaded: allLoaded, updateInfo: updateInfo)
        viewDataRelay.accept(viewData)
    }

    private func sync(syncing: Bool) {
        queue.async {
            self._sync(syncing: syncing)
        }
    }

    private func _sync(syncing: Bool) {
        syncingRelay.accept(syncing)
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

extension BaseTransactionsViewModel {

    var typeFilterIndexDriver: Driver<Int> {
        typeFilterIndexRelay.asDriver()
    }

    var viewDataDriver: Driver<ViewData> {
        viewDataRelay.asDriver()
    }

    var syncingDriver: Driver<Bool> {
        syncingRelay.asDriver()
    }

    var resetEnabledDriver: Driver<Bool> {
        resetEnabledRelay.asDriver()
    }

    var typeFilterViewItems: [FilterView.ViewItem] {
        factory.typeFilterViewItems(typeFilters: TransactionTypeFilter.allCases)
    }

    func onSelectTypeFilter(index: Int) {
        let typeFilters = TransactionTypeFilter.allCases

        guard index < typeFilters.count else {
            return
        }

        service.set(typeFilter: typeFilters[index])
    }

    func record(uid: String) -> TransactionRecord? {
        service.record(uid: uid)
    }

    func onDisplay(sectionIndex: Int, index: Int) {
        queue.async {
            guard sectionIndex < self.sectionViewItems.count, index < self.sectionViewItems[sectionIndex].viewItems.count else {
                return
            }

            var itemIndex = index

            for i in 0..<sectionIndex {
                itemIndex += self.sectionViewItems[i].viewItems.count
            }

            self.service.loadMoreIfRequired(index: itemIndex)
            self.service.fetchRate(index: itemIndex)
        }
    }

    func onTapReset() {
        service.reset()
    }

}

extension BaseTransactionsViewModel {

    class SectionViewItem {
        let title: String
        var viewItems: [ViewItem]

        init(title: String, viewItems: [ViewItem]) {
            self.title = title
            self.viewItems = viewItems
        }
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
        let spam: Bool
    }

    enum IconType {
        case icon(imageUrl: String?, placeholderImageName: String)
        case doubleIcon(frontType: TransactionImageComponent.ImageType, frontUrl: String?, frontPlaceholder: String, backType: TransactionImageComponent.ImageType, backUrl: String?, backPlaceholder: String)
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

    struct BlockchainViewItem {
        let uid: String?
        let title: String
        let selected: Bool
    }

    struct ViewData {
        let sectionViewItems: [SectionViewItem]
        let allLoaded: Bool?
        let updateInfo: UpdateInfo?
    }

    struct UpdateInfo {
        let sectionIndex: Int
        let index: Int
    }

}
