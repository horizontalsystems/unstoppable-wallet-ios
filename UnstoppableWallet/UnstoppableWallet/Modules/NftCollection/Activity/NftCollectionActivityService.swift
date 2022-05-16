import RxSwift
import RxRelay

class NftCollectionActivityService {
    private let collectionUid: String
    private let provider: HsNftProvider
    private let coinPriceService: WalletCoinPriceService
    private var disposeBag = DisposeBag()

    let filterEventTypes: [NftEvent.EventType] = [.sale, .list, .offer, .bid, .transfer]

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    private let eventTypeRelay = PublishRelay<NftEvent.EventType?>()
    var eventType: NftEvent.EventType? = .sale {
        didSet {
            if eventType != oldValue {
                eventTypeRelay.accept(eventType)
                _loadInitial()
            }
        }
    }

    private var cursor: String?
    private var loadingMore = false

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.nft-collection-activity-service", qos: .userInitiated)

    init(collectionUid: String, provider: HsNftProvider, coinPriceService: WalletCoinPriceService) {
        self.collectionUid = collectionUid
        self.provider = provider
        self.coinPriceService = coinPriceService

        _loadInitial()
    }

    private func _loadInitial() {
        disposeBag = DisposeBag()

        state = .loading

        provider.eventsSingle(collectionUid: collectionUid, eventType: eventType)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] pagedEvents in
                    self?.handle(pagedEvents: pagedEvents)
                }, onError: { [weak self] error in
                    self?.handle(error: error)
                })
                .disposed(by: disposeBag)
    }

    private func _loadMore() {
        guard cursor != nil else {
            return
        }

        guard !loadingMore else {
            return
        }

        loadingMore = true

        provider.eventsSingle(collectionUid: collectionUid, eventType: eventType, cursor: cursor)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] pagedEvents in
                    self?.handleMore(pagedEvents: pagedEvents)
                    self?.loadingMore = false
                }, onError: { [weak self] error in
                    self?.loadingMore = false
                })
                .disposed(by: disposeBag)
    }

    private func handle(pagedEvents: PagedNftEvents) {
        queue.async {
            self.cursor = pagedEvents.cursor
            self.state = .loaded(items: self.items(events: pagedEvents.events), allLoaded: self.cursor == nil)
        }
    }

    private func handleMore(pagedEvents: PagedNftEvents) {
        queue.async {
            guard case .loaded(let items, _) = self.state else {
                return
            }

            self.cursor = pagedEvents.cursor
            self.state = .loaded(items: items + self.items(events: pagedEvents.events), allLoaded: self.cursor == nil)
        }
    }

    private func handle(error: Error) {
        queue.async {
            self.state = .failed(error: error)
        }
    }

    private func items(events: [NftEvent]) -> [Item] {
        let items = events.map { event in
            Item(event: event)
        }

        updatePriceItems(items: items, map: coinPriceService.itemMap(coinUids: Array(allCoinUids(items: items))))

        return items
    }

    private func allCoinUids(items: [Item]) -> Set<String> {
        var uids = Set<String>()

        for item in items {
            if let amount = item.event.amount {
                uids.insert(amount.platformCoin.coin.uid)
            }
        }

        return uids
    }

    private func updatePriceItems(items: [Item], map: [String: WalletCoinPriceService.Item]) {
        for item in items {
            item.priceItem = item.event.amount.flatMap { map[$0.platformCoin.coin.uid] }
        }
    }

}

extension NftCollectionActivityService: IWalletRateServiceDelegate {

    func didUpdateBaseCurrency() {
        queue.async {
            guard case .loaded(let items, let allLoaded) = self.state else {
                return
            }

            self.updatePriceItems(items: items, map: self.coinPriceService.itemMap(coinUids: Array(self.allCoinUids(items: items))))
            self.state = .loaded(items: items, allLoaded: allLoaded)
        }
    }

    func didUpdate(itemsMap: [String: WalletCoinPriceService.Item]) {
        queue.async {
            guard case .loaded(let items, let allLoaded) = self.state else {
                return
            }

            self.updatePriceItems(items: items, map: itemsMap)
            self.state = .loaded(items: items, allLoaded: allLoaded)
        }
    }

}

extension NftCollectionActivityService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var eventTypeObservable: Observable<NftEvent.EventType?> {
        eventTypeRelay.asObservable()
    }

    func reload() {
        queue.async {
            self._loadInitial()
        }
    }

    func loadMore() {
        queue.async {
            self._loadMore()
        }
    }

    func asset(tokenId: String) -> NftAsset? {
        guard case .loaded(let items, _) = state else {
            return nil
        }

        return items.first { $0.event.asset.tokenId == tokenId }?.event.asset
    }

}

extension NftCollectionActivityService {

    enum State {
        case loading
        case loaded(items: [Item], allLoaded: Bool)
        case failed(error: Error)
    }

    class Item {
        let event: NftEvent
        var priceItem: WalletCoinPriceService.Item?

        init(event: NftEvent) {
            self.event = event
        }
    }

}
