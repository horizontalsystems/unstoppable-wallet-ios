import RxSwift
import RxRelay
import RxCocoa
import CurrencyKit
import MarketKit

class NftActivityViewModel {
    private let service: NftActivityService
    private let disposeBag = DisposeBag()

    private let eventTypeRelay = BehaviorRelay<String>(value: "")

    private let viewItemRelay = BehaviorRelay<ViewItem?>(value: nil)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let syncErrorRelay = BehaviorRelay<Bool>(value: false)

    init(service: NftActivityService) {
        self.service = service

        subscribe(disposeBag, service.eventTypeObservable) { [weak self] in self?.sync(eventType: $0) }
        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(eventType: service.eventType)
        sync(state: service.state)
    }

    private func sync(eventType: NftEventMetadata.EventType?) {
        eventTypeRelay.accept(title(eventType: eventType))
    }

    private func sync(state: NftActivityService.State) {
        switch state {
        case .loading:
            viewItemRelay.accept(nil)
            loadingRelay.accept(true)
            syncErrorRelay.accept(false)
        case .loaded(let items, let allLoaded):
            let viewItem = ViewItem(
                    eventViewItems: items.map { eventViewItem(item: $0) },
                    allLoaded: allLoaded
            )

            viewItemRelay.accept(viewItem)
            loadingRelay.accept(false)
            syncErrorRelay.accept(false)
        case .failed:
            viewItemRelay.accept(nil)
            loadingRelay.accept(false)
            syncErrorRelay.accept(true)
        }
    }

    private func eventViewItem(item: NftActivityService.Item) -> EventViewItem {
        let event = item.event

        var coinPrice = ""
        var fiatPrice: String?

        if let amount = event.amount {
            let coinValue = CoinValue(kind: .token(token: amount.token), value: amount.value)
            if let value = ValueFormatter.instance.formatShort(coinValue: coinValue) {
                coinPrice = value
            }

            if let priceItem = item.priceItem {
                fiatPrice = ValueFormatter.instance.formatShort(currency: priceItem.price.currency, value: amount.value * priceItem.price.value)
            }
        }

        let type: String

        if let eventType = event.type {
            type = "nft.activity.event_type.\(eventType)".localized
        } else {
            type = "nft.activity.event_type.unknown".localized
        }

        return EventViewItem(
                providerCollectionUid: event.asset.providerCollectionUid,
                nftUid: event.asset.nftUid,
                type: type,
                date: DateHelper.instance.formatFullTime(from: event.date),
                imageUrl: event.asset.previewImageUrl,
                coinPrice: coinPrice,
                fiatPrice: fiatPrice
        )
    }

    private func title(eventType: NftEventMetadata.EventType?) -> String {
        guard let eventType = eventType else {
            return "nft.activity.event_type.all".localized
        }

        return "nft.activity.event_type.\(eventType)".localized
    }

}

extension NftActivityViewModel: IDropdownFilterHeaderViewModel {

    var dropdownTitle: String {
        "nft.activity.event_types".localized
    }

    var dropdownViewItems: [AlertViewItem] {
        var items = [AlertViewItem]()

        items.append(AlertViewItem(text: title(eventType: nil), selected: service.eventType == nil))

        for eventType in service.filterEventTypes {
            items.append(AlertViewItem(text: title(eventType: eventType), selected: service.eventType == eventType))
        }

        return items
    }

    var dropdownValueDriver: Driver<String> {
        eventTypeRelay.asDriver()
    }

    func onSelectDropdown(index: Int) {
        if index == 0 {
            service.eventType = nil
        } else {
            service.eventType = service.filterEventTypes[index - 1]
        }
    }

}

extension NftActivityViewModel {

    var viewItemDriver: Driver<ViewItem?> {
        viewItemRelay.asDriver()
    }

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var syncErrorDriver: Driver<Bool> {
        syncErrorRelay.asDriver()
    }

    func onLoad() {
        service.loadInitial()
    }

    func onTapRetry() {
        service.reload()
    }

    func onReachBottom() {
        service.loadMore()
    }

}

extension NftActivityViewModel {

    struct ViewItem {
        let eventViewItems: [EventViewItem]
        let allLoaded: Bool
    }

    struct EventViewItem {
        let providerCollectionUid: String
        let nftUid: NftUid
        let type: String
        let date: String
        let imageUrl: String?
        let coinPrice: String
        let fiatPrice: String?
    }

}
