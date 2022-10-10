import Foundation
import RxSwift
import RxRelay
import MarketKit

class NftActivityService {
    private let eventListType: NftActivityModule.NftEventListType
    private let nftMetadataManager: NftMetadataManager
    private let coinPriceService: WalletCoinPriceService
    private var disposeBag = DisposeBag()

    let filterEventTypes: [NftEventMetadata.EventType] = [.sale, .list, .offer, .bid, .transfer]

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    private let eventTypeRelay = PublishRelay<NftEventMetadata.EventType?>()
    var eventType: NftEventMetadata.EventType? = .sale {
        didSet {
            if eventType != oldValue {
                eventTypeRelay.accept(eventType)
                queue.async {
                    self._loadInitial()
                }
            }
        }
    }

    private var paginationData: PaginationData?
    private var loadingMore = false

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.nft-collection-activity-service", qos: .userInitiated)

    init(eventListType: NftActivityModule.NftEventListType, defaultEventType: NftEventMetadata.EventType?, nftMetadataManager: NftMetadataManager, coinPriceService: WalletCoinPriceService) {
        self.eventListType = eventListType
        eventType = defaultEventType
        self.nftMetadataManager = nftMetadataManager
        self.coinPriceService = coinPriceService
    }

    private func single(paginationData: PaginationData? = nil) -> Single<([NftEventMetadata], PaginationData?)> {
        switch eventListType {
        case let .collection(blockchainType, providerUid): return nftMetadataManager.collectionEventsMetadataSingle(blockchainType: blockchainType, providerUid: providerUid, eventType: eventType, paginationData: paginationData)
        case let .asset(nftUid): return nftMetadataManager.assetEventsMetadataSingle(nftUid: nftUid, eventType: eventType, paginationData: paginationData)
        }
    }

    private func _loadInitial() {
        disposeBag = DisposeBag()

        state = .loading

        single()
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] events, paginationData in
                    self?.handle(events: events, paginationData: paginationData)
                }, onError: { [weak self] error in
                    self?.handle(error: error)
                })
                .disposed(by: disposeBag)
    }

    private func _loadMore() {
        guard paginationData != nil else {
            return
        }

        guard !loadingMore else {
            return
        }

        loadingMore = true

        single(paginationData: paginationData)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] events, paginationData in
                    self?.handleMore(events: events, paginationData: paginationData)
                    self?.loadingMore = false
                }, onError: { [weak self] error in
                    self?.loadingMore = false
                })
                .disposed(by: disposeBag)
    }

    private func handle(events: [NftEventMetadata], paginationData: PaginationData?) {
        queue.async {
            self.paginationData = paginationData
            self.state = .loaded(items: self.items(events: events), allLoaded: self.paginationData == nil)
        }
    }

    private func handleMore(events: [NftEventMetadata], paginationData: PaginationData?) {
        queue.async {
            guard case .loaded(let items, _) = self.state else {
                return
            }

            self.paginationData = paginationData
            self.state = .loaded(items: items + self.items(events: events), allLoaded: self.paginationData == nil)
        }
    }

    private func handle(error: Error) {
        queue.async {
            self.state = .failed(error: error)
        }
    }

    private func items(events: [NftEventMetadata]) -> [Item] {
        let items = events.map { event in
            Item(event: event)
        }

        updatePriceItems(items: items, map: coinPriceService.itemMap(tokens: Array(allTokens(items: items))))

        return items
    }

    private func allTokens(items: [Item]) -> Set<Token> {
        var tokens = Set<Token>()

        for item in items {
            if let amount = item.event.amount {
                tokens.insert(amount.token)
            }
        }

        return tokens
    }

    private func updatePriceItems(items: [Item], map: [String: WalletCoinPriceService.Item]) {
        for item in items {
            item.priceItem = item.event.amount.flatMap { map[$0.token.coin.uid] }
        }
    }

}

extension NftActivityService: IWalletCoinPriceServiceDelegate {

    func didUpdateBaseCurrency() {
        queue.async {
            guard case .loaded(let items, let allLoaded) = self.state else {
                return
            }

            self.updatePriceItems(items: items, map: self.coinPriceService.itemMap(tokens: Array(self.allTokens(items: items))))
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

    var eventTypeObservable: Observable<NftEventMetadata.EventType?> {
        eventTypeRelay.asObservable()
    }

    func loadInitial() {
        queue.async {
            self._loadInitial()
        }
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
        let event: NftEventMetadata
        var priceItem: WalletCoinPriceService.Item?

        init(event: NftEventMetadata) {
            self.event = event
        }
    }

}
