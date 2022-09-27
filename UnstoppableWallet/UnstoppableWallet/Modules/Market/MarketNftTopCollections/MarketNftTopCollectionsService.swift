import RxSwift
import RxRelay
import CurrencyKit
import MarketKit

struct NftCollectionItem {
    let index: Int
    let collection: NftTopCollection
}

class MarketNftTopCollectionsService {
    typealias Item = NftCollectionItem

    private let disposeBag = DisposeBag()
    private var syncDisposeBag = DisposeBag()

    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit

    private var internalState: MarketListServiceState<NftTopCollection> = .loading

    private let stateRelay = PublishRelay<MarketListServiceState<NftCollectionItem>>()
    private(set) var state: MarketListServiceState<NftCollectionItem> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    var sortType: MarketNftTopCollectionsModule.SortType = .highestVolume { didSet { syncIfPossible() } }
    var timePeriod: HsTimePeriod { didSet { syncIfPossible() } }

    init(marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, timePeriod: HsTimePeriod) {
        self.marketKit = marketKit
        self.currencyKit = currencyKit
        self.timePeriod = timePeriod

        sync()
    }

    private func sync() {
        syncDisposeBag = DisposeBag()

        if case .failed = state {
            state = .loading
        }

        marketKit.nftTopCollectionsSingle()
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] collections in
                    self?.internalState = .loaded(items: collections, softUpdate: false, reorder: false)

                    self?.sync(collections: collections)
                }, onError: { [weak self] error in
                    self?.state = .failed(error: error)
                })
                .disposed(by: syncDisposeBag)
    }

    private func sync(collections: [NftTopCollection], reorder: Bool = false) {
        let sortedCollections = collections.sorted(sortType: sortType, timePeriod: timePeriod)
        let items = sortedCollections.enumerated().map { NftCollectionItem(index: $0 + 1, collection: $1) }
        state = .loaded(items: items, softUpdate: false, reorder: reorder)
    }

    private func syncIfPossible() {
        guard case .loaded(let collections, _, _) = internalState else {
            return
        }

        sync(collections: collections, reorder: true)
    }

}

extension MarketNftTopCollectionsService: IMarketListService {

    var stateObservable: Observable<MarketListServiceState<NftCollectionItem>> {
        stateRelay.asObservable()
    }

    func topCollection(uid: String) -> NftTopCollection? {
        guard case .loaded(let collections, _, _) = internalState else {
            return nil
        }

        return collections.first { $0.uid == uid }
    }

    func refresh() {
        sync()
    }

}

extension MarketNftTopCollectionsService: IMarketListNftTopCollectionDecoratorService {
}
