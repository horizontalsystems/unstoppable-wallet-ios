import RxSwift
import RxRelay
import CurrencyKit

struct NftCollectionItem {
    let index: Int
    let collection: NftCollection
}

class MarketOverviewNftCollectionsService {
    private let listCount = 5

    private let provider: HsNftProvider
    private let currencyKit: CurrencyKit.Kit
    private var disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<DataStatus<[NftCollectionItem]>>()
    private(set) var state: DataStatus<[NftCollectionItem]> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(provider: HsNftProvider, currencyKit: CurrencyKit.Kit) {
        self.provider = provider
        self.currencyKit = currencyKit

        sync()
    }

    private func sync() {
        disposeBag = DisposeBag()

        state = .loading

        let listCount = listCount
        provider.collectionsSingle()
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] collections in
                    let sortedCollections = Array(collections.sorted(sortType: .highestVolume, volumeRange: .day).prefix(listCount))
                    self?.state = .completed(sortedCollections.enumerated().map { NftCollectionItem(index: $0 + 1, collection: $1)})
                }, onError: { [weak self] error in
                    self?.state = .failed(error)
                })
                .disposed(by: disposeBag)
    }

}

extension MarketOverviewNftCollectionsService {

    var stateObservable: Observable<DataStatus<[NftCollectionItem]>> {
        stateRelay.asObservable()
    }

    func refresh() {
        sync()
    }

}
