import RxSwift
import RxRelay
import CurrencyKit

class MarketOverviewNftCollectionsService {
    private let listCount = 5

    private let provider: HsNftProvider
    private let currencyKit: CurrencyKit.Kit
    private var disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<DataStatus<[NftCollection]>>()
    private(set) var state: DataStatus<[NftCollection]> = .loading {
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
        provider.collectionsSingle(currencyCode: currency.code)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] collections in
                    let sortedCollections = Array(collections.sorted(sortingField: .highestCap, priceChangeType: .day).prefix(listCount))
                    self?.state = .completed(sortedCollections)
                }, onError: { [weak self] error in
                    self?.state = .failed(error)
                })
                .disposed(by: disposeBag)
    }

}

extension MarketOverviewNftCollectionsService {

    var stateObservable: Observable<DataStatus<[NftCollection]>> {
        stateRelay.asObservable()
    }

    var currency: Currency {
        currencyKit.baseCurrency
    }

    func refresh() {
        sync()
    }

    func collection(uid: String) -> NftCollection? {
        if case let .completed(collections) = state {
            return collections.first { $0.uid == uid }
        }
        return nil
    }

}
