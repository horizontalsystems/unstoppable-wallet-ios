import Foundation
import RxSwift
import RxCocoa
import MarketKit
import ComponentKit

class TransactionsViewModel {
    private let service: TransactionsService
    private let factory: TransactionsViewItemFactory
    private let disposeBag = DisposeBag()

    private let typeFilterIndexRelay = BehaviorRelay<Int>(value: 0)
    private let blockchainTitleRelay = BehaviorRelay<String?>(value: nil)
    private let tokenTitleRelay = BehaviorRelay<String?>(value: nil)

    private let viewDataRelay = BehaviorRelay<ViewData>(value: ViewData(sectionViewItems: [], allLoaded: true, updateInfo: nil))
    private var viewStatusRelay = BehaviorRelay<ViewStatus>(value: ViewStatus(showProgress: false, messageType: nil))
    private var resetEnabledRelay = BehaviorRelay<Bool>(value: false)

    private var sectionViewItems = [SectionViewItem]()

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.transactions_view_model", qos: .userInitiated)

    init(service: TransactionsService, factory: TransactionsViewItemFactory) {
        self.service = service
        self.factory = factory

        subscribe(disposeBag, service.typeFilterObservable) { [weak self] in self?.sync(typeFilter: $0) }
        subscribe(disposeBag, service.blockchainObservable) { [weak self] in self?.syncBlockchainTitle(blockchain: $0) }
        subscribe(disposeBag, service.configuredTokenObservable) { [weak self] in self?.syncTokenTitle(configuredToken: $0) }
        subscribe(disposeBag, service.itemDataObservable) { [weak self] in self?.sync(itemData: $0) }
        subscribe(disposeBag, service.itemUpdatedObservable) { [weak self] in self?.syncUpdated(item: $0) }
        subscribe(disposeBag, service.syncingObservable) { [weak self] in self?.syncViewStatus(syncing: $0) }
        subscribe(disposeBag, service.canResetObservable) { [weak self] in self?.sync(canReset: $0) }

        syncBlockchainTitle(blockchain: service.blockchain)
        syncTokenTitle(configuredToken: service.configuredToken)
        _sync(itemData: service.itemData)
        _syncViewStatus(syncing: service.syncing)
        sync(canReset: service.canReset)
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

    private func syncBlockchainTitle(blockchain: Blockchain?) {
        let title: String

        if let blockchain = blockchain {
            title = blockchain.name
        } else {
            title = "transactions.all_blockchains".localized
        }

        blockchainTitleRelay.accept(title)
    }

    private func syncTokenTitle(configuredToken: ConfiguredToken?) {
        var title: String

        if let configuredToken = configuredToken {
            title = configuredToken.token.coin.code

            if let badge = configuredToken.badge {
                title += " (\(badge))"
            }
        } else {
            title = "transactions.all_coins".localized
        }

        tokenTitleRelay.accept(title)
    }

    private func sync(itemData: TransactionsService.ItemData) {
        queue.async {
            self._sync(itemData: itemData)
        }
    }

    private func _sync(itemData: TransactionsService.ItemData) {
        let viewItems = itemData.items.map { factory.viewItem(item: $0) }
        sectionViewItems = sectionViewItems(viewItems: viewItems)

        _reportViewData(allLoaded: itemData.allLoaded)
        _syncViewStatus(syncing: service.syncing)
    }

    private func syncUpdated(item: TransactionsService.Item) {
        queue.async {
            self._syncUpdated(item: item)
        }
    }

    private func _syncUpdated(item: TransactionsService.Item) {
        for (sectionIndex, section) in sectionViewItems.enumerated() {
            if let rowIndex = section.viewItems.firstIndex(where: { $0.uid == item.record.uid }) {
                let viewItem = factory.viewItem(item: item)
                sectionViewItems[sectionIndex].viewItems[rowIndex] = viewItem
                _reportViewData(updateInfo: UpdateInfo(sectionIndex: sectionIndex, index: rowIndex))
            }
        }
    }

    private func _reportViewData(allLoaded: Bool? = nil, updateInfo: UpdateInfo? = nil) {
        let viewData = ViewData(sectionViewItems: sectionViewItems, allLoaded: allLoaded, updateInfo: updateInfo)
        viewDataRelay.accept(viewData)
    }

    private func syncViewStatus(syncing: Bool) {
        queue.async {
            self._syncViewStatus(syncing: syncing)
        }
    }

    private func _syncViewStatus(syncing: Bool) {
        let viewStatus = ViewStatus(
                showProgress: syncing,
                messageType: sectionViewItems.isEmpty ? (syncing ? .syncing : .empty) : nil
        )

        viewStatusRelay.accept(viewStatus)
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

    var typeFilterIndexDriver: Driver<Int> {
        typeFilterIndexRelay.asDriver()
    }

    var blockchainTitleDriver: Driver<String?> {
        blockchainTitleRelay.asDriver()
    }

    var tokenTitleDriver: Driver<String?> {
        tokenTitleRelay.asDriver()
    }

    var viewDataDriver: Driver<ViewData> {
        viewDataRelay.asDriver()
    }

    var viewStatusDriver: Driver<ViewStatus> {
        viewStatusRelay.asDriver()
    }

    var resetEnabledDriver: Driver<Bool> {
        resetEnabledRelay.asDriver()
    }

    var typeFilterViewItems: [FilterHeaderView.ViewItem] {
        factory.typeFilterViewItems(typeFilters: TransactionTypeFilter.allCases)
    }

    var blockchainViewItems: [BlockchainViewItem] {
        [BlockchainViewItem(uid: nil, title: "transactions.all_blockchains".localized, selected: service.blockchain == nil)] +
                service.allBlockchains.sorted { $0.type.order < $1.type.order }.map { blockchain in
                    BlockchainViewItem(uid: blockchain.uid, title: blockchain.name, selected: service.blockchain == blockchain)
                }
    }

    var configuredToken: ConfiguredToken? {
        service.configuredToken
    }

    func onSelectTypeFilter(index: Int) {
        let typeFilters = TransactionTypeFilter.allCases

        guard index < typeFilters.count else {
            return
        }

        service.set(typeFilter: typeFilters[index])
    }

    func onSelectBlockchain(uid: String?) {
        service.set(blockchain: service.allBlockchains.first(where: { $0.uid == uid }))
    }

    func onSelect(configuredToken: ConfiguredToken?) {
        service.set(configuredToken: configuredToken)
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

extension TransactionsViewModel {

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

    struct ViewStatus {
        let showProgress: Bool
        let messageType: MessageType?
    }

    enum MessageType {
        case syncing
        case empty
    }

}
