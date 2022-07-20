import RxSwift
import RxRelay
import MarketKit

class NftActivityService {
    private let eventListType: NftActivityModule.NftEventListType
    private let marketKit: MarketKit.Kit
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

    init(eventListType: NftActivityModule.NftEventListType, defaultEventType: NftEvent.EventType?, marketKit: MarketKit.Kit, coinPriceService: WalletCoinPriceService) {
        self.eventListType = eventListType
        eventType = defaultEventType
        self.marketKit = marketKit
        self.coinPriceService = coinPriceService

        _loadInitial()
    }

    private func single(cursor: String? = nil) -> Single<PagedNftEvents> {
        switch eventListType {
        case .collection(let uid): return marketKit.nftCollectionEventsSingle(collectionUid: uid, eventType: eventType, cursor: cursor)
        case .asset(let contractAddress, let tokenId): return marketKit.nftAssetEventsSingle(contractAddress: contractAddress, tokenId: tokenId, eventType: eventType, cursor: cursor)
        }
    }

    private func _loadInitial() {
        disposeBag = DisposeBag()

        state = .loading

        single()
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

        single(cursor: cursor)
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
                uids.insert(amount.token.coin.uid)
            }
        }

        return uids
    }

    private func updatePriceItems(items: [Item], map: [String: WalletCoinPriceService.Item]) {
        for item in items {
            item.priceItem = item.event.amount.flatMap { map[$0.token.coin.uid] }
        }
    }

}

extension NftActivityService: IWalletRateServiceDelegate {

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

extension NftActivityService {

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

}

extension NftActivityService {

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
