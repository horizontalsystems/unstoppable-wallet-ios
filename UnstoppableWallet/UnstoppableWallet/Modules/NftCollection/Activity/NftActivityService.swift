import Foundation
import RxSwift
import RxRelay
import MarketKit

class NftActivityService {
    private let eventListType: NftActivityModule.NftEventListType
    private let nftMetadataManager: NftMetadataManager
    private let coinPriceService: WalletCoinPriceService
    private var disposeBag = DisposeBag()

    let filterEventTypes: [NftEventMetadata.EventType] = [.sale, .list, .offer, .transfer, .mint]

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

    private let contractIndexRelay = PublishRelay<Int>()
    var contractIndex: Int = 0 {
        didSet {
            if contractIndex != oldValue {
                contractIndexRelay.accept(contractIndex)
                queue.async {
                    self._loadInitial()
                }
            }
        }
    }

    private let contractsRelay = PublishRelay<[NftContractMetadata]>()
    private(set) var contracts: [NftContractMetadata] = [] {
        didSet {
            contractsRelay.accept(contracts)
        }
    }

    private var paginationData: PaginationData?
    private var loadingMore = false

    private let queue = DispatchQueue(label: "\(AppConfig.label).nft-collection-activity-service", qos: .userInitiated)

    init(eventListType: NftActivityModule.NftEventListType, defaultEventType: NftEventMetadata.EventType?, nftMetadataManager: NftMetadataManager, coinPriceService: WalletCoinPriceService) {
        self.eventListType = eventListType
        eventType = defaultEventType
        self.nftMetadataManager = nftMetadataManager
        self.coinPriceService = coinPriceService
    }

    private func single(paginationData: PaginationData? = nil) -> Single<([NftEventMetadata], PaginationData?)> {
        switch eventListType {
        case let .collection(blockchainType, _):
            if contracts.count > contractIndex {
                return nftMetadataManager.collectionEventsMetadataSingle(blockchainType: blockchainType, contractAddress: contracts[contractIndex].address, eventType: eventType, paginationData: paginationData)
            } else {
                return Single.error(FetchError.noContract)
            }
        case let .asset(nftUid):
            return nftMetadataManager.assetEventsMetadataSingle(nftUid: nftUid, eventType: eventType, paginationData: paginationData)
        }
    }

    private func _loadInitial() {
        disposeBag = DisposeBag()

        state = .loading

        switch eventListType {
        case let .collection(blockchainType, providerUid):
            if contracts.isEmpty {
                nftMetadataManager.collectionMetadataSingle(blockchainType: blockchainType, providerUid: providerUid)
                        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                        .subscribe(onSuccess: { [weak self] collection in
                            if collection.contracts.isEmpty {
                                self?.handle(error: FetchError.noContract)
                            } else {
                                self?.contracts = collection.contracts
                                self?.loadInitial()
                            }
                        }, onError: { [weak self] error in
                            self?.handle(error: error)
                        })
                        .disposed(by: disposeBag)
                return
            }
        default: ()
        }

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

        updatePriceItems(items: items, map: coinPriceService.itemMap(coinUids: Array(allCoinUids(items: items))))

        return items
    }

    private func allCoinUids(items: [Item]) -> Set<String> {
        var coinUids = Set<String>()

        for item in items {
            if let amount = item.event.price {
                coinUids.insert(amount.token.coin.uid)
            }
        }

        return coinUids
    }

    private func updatePriceItems(items: [Item], map: [String: WalletCoinPriceService.Item]) {
        for item in items {
            item.priceItem = item.event.price.flatMap { map[$0.token.coin.uid] }
        }
    }

}

extension NftActivityService: IWalletCoinPriceServiceDelegate {

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

    var eventTypeObservable: Observable<NftEventMetadata.EventType?> {
        eventTypeRelay.asObservable()
    }

    var contractIndexObservable: Observable<Int> {
        contractIndexRelay.asObservable()
    }

    var contractsObservable: Observable<[NftContractMetadata]> {
        contractsRelay.asObservable()
    }

    var blockchainType: BlockchainType? {
        switch eventListType {
        case .collection(let blockchainType, _): return blockchainType
        default: return nil
        }
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

    enum FetchError: Error {
        case noContract
    }

}
