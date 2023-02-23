import RxSwift
import RxRelay
import RxCocoa
import CurrencyKit
import MarketKit

class NftActivityViewModel {
    private let service: NftActivityService
    private let disposeBag = DisposeBag()

    private let eventTypeRelay = BehaviorRelay<String>(value: "")
    private let contractRelay = BehaviorRelay<String?>(value: nil)

    private let viewItemRelay = BehaviorRelay<ViewItem?>(value: nil)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let syncErrorRelay = BehaviorRelay<Bool>(value: false)

    init(service: NftActivityService) {
        self.service = service

        subscribe(disposeBag, service.eventTypeObservable) { [weak self] in self?.sync(eventType: $0) }
        subscribe(disposeBag, service.contractsObservable) { [weak self] _ in self?.syncContracts() }
        subscribe(disposeBag, service.contractIndexObservable) { [weak self] _ in self?.syncContracts() }
        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(eventType: service.eventType)
        sync(state: service.state)
    }

    private func sync(eventType: NftEventMetadata.EventType?) {
        eventTypeRelay.accept(title(eventType: eventType))
    }

    private func syncContracts() {
        if service.contracts.count > 1 {
            contractRelay.accept(service.contracts[service.contractIndex].name)
        } else {
            contractRelay.accept(nil)
        }
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

        if let price = event.price {
            let coinValue = CoinValue(kind: .token(token: price.token), value: price.value)
            if let value = ValueFormatter.instance.formatShort(coinValue: coinValue) {
                coinPrice = value
            }

            if let priceItem = item.priceItem {
                fiatPrice = ValueFormatter.instance.formatShort(currency: priceItem.price.currency, value: price.value * priceItem.price.value)
            }
        }

        let type: String

        if let eventType = event.type {
            type = "nft.activity.event_type.\(eventType)".localized
        } else {
            type = "nft.activity.event_type.unknown".localized
        }

        return EventViewItem(
                nftUid: event.nftUid,
                type: type,
                date: DateHelper.instance.formatFullTime(from: event.date),
                imageUrl: event.previewImageUrl,
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

extension NftActivityViewModel {

    var eventTypeDriver: Driver<String> {
        eventTypeRelay.asDriver()
    }

    var contractDriver: Driver<String?> {
        contractRelay.asDriver()
    }

    var viewItemDriver: Driver<ViewItem?> {
        viewItemRelay.asDriver()
    }

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var syncErrorDriver: Driver<Bool> {
        syncErrorRelay.asDriver()
    }

    var contractViewItems: [SelectorModule.ViewItem] {
        guard let blockchainType = service.blockchainType else {
            return []
        }

        return service.contracts.enumerated().map { index, contract in
            SelectorModule.ViewItem(
                    image: .url(blockchainType.imageUrl, placeholder: "placeholder_rectangle_32"),
                    title: contract.name,
                    subtitle: contract.address.shortened,
                    badge: contract.schema,
                    selected: service.contractIndex == index
            )
        }
    }

    var eventTypeViewItems: [AlertViewItem] {
        var items = [AlertViewItem]()

        items.append(AlertViewItem(text: title(eventType: nil), selected: service.eventType == nil))

        for eventType in service.filterEventTypes {
            items.append(AlertViewItem(text: title(eventType: eventType), selected: service.eventType == eventType))
        }

        return items
    }

    func onSelectEventType(index: Int) {
        if index == 0 {
            service.eventType = nil
        } else {
            service.eventType = service.filterEventTypes[index - 1]
        }
    }

    func onSelectContract(index: Int) {
        service.contractIndex = index
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
        let nftUid: NftUid?
        let type: String
        let date: String
        let imageUrl: String?
        let coinPrice: String
        let fiatPrice: String?
    }

}
