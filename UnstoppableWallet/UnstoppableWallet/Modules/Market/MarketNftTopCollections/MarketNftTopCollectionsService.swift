import RxSwift
import RxRelay
import CurrencyKit

class MarketNftTopCollectionsService {
    typealias Item = NftCollectionItem

    private let disposeBag = DisposeBag()
    private var syncDisposeBag = DisposeBag()

    private let provider: HsNftProvider
    private let currencyKit: CurrencyKit.Kit

    private var internalState: MarketListServiceState<NftCollection> = .loading

    private let stateRelay = PublishRelay<MarketListServiceState<NftCollectionItem>>()
    private(set) var state: MarketListServiceState<NftCollectionItem> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    var sortType: MarketNftTopCollectionsModule.SortType = .highestVolume { didSet { syncIfPossible() } }
    var volumeRange: MarketNftTopCollectionsModule.VolumeRange = .day { didSet { syncIfPossible() } }

    init(provider: HsNftProvider, currencyKit: CurrencyKit.Kit) {
        self.provider = provider
        self.currencyKit = currencyKit

        sync()
    }

    private func sync() {
        syncDisposeBag = DisposeBag()

        if case .failed = state {
            state = .loading
        }

        provider.collectionsSingle()
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] collections in
                    self?.internalState = .loaded(items: collections, softUpdate: false, reorder: false)

                    self?.sync(collections: collections)
                }, onError: { [weak self] error in
                    self?.state = .failed(error: error)
                })
                .disposed(by: syncDisposeBag)
    }

    private func sync(collections: [NftCollection], reorder: Bool = false) {
        let sortedCollections = collections.sorted(sortType: sortType, volumeRange: volumeRange)
        let items = sortedCollections.enumerated().map { NftCollectionItem(index: $0 + 1, collection: $1) }
        state = .loaded(items: items, softUpdate: false, reorder: reorder)
    }

    private func syncIfPossible() {
        guard case .loaded(let collections, _, _) = internalState else {
            return
        }

        sync(collections: collections, reorder: true)
    }

    func collection(uid: String) -> NftCollection? {
        if case let .loaded(collections, _, _) = internalState {
            return collections.first { $0.uid == uid }
        }
        return nil
    }

}

extension MarketNftTopCollectionsService: IMarketListService {

    var stateObservable: Observable<MarketListServiceState<NftCollectionItem>> {
        stateRelay.asObservable()
    }

    func refresh() {
        sync()
    }

}

extension MarketNftTopCollectionsService: IMarketListCoinUidService {

    func coinUid(index: Int) -> String? {
        nil
    }

}

extension MarketNftTopCollectionsService: IMarketListDecoratorService {

    var initialMarketFieldIndex: Int {
        0
    }

    var currency: Currency {
        currencyKit.baseCurrency
    }

    var priceChangeType: MarketModule.PriceChangeType {
        .day
    }

    func onUpdate(marketFieldIndex: Int) {
        if case .loaded(let marketInfos, _, _) = state {
            stateRelay.accept(.loaded(items: marketInfos, softUpdate: false, reorder: false))
        }
    }

}
