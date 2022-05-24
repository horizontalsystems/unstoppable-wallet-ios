import Foundation
import RxSwift
import RxRelay
import CurrencyKit
import MarketKit

class MarketOverviewNftCollectionsService: IMarketListNftTopCollectionDecoratorService {
    private let baseService: MarketOverviewService
    private let disposeBag = DisposeBag()

    var timePeriod: HsTimePeriod = .week1 {
        didSet {
            sync()
        }
    }

    private let collectionsRelay = PublishRelay<[NftCollection]?>()
    private(set) var collections: [NftCollection]? {
        didSet {
            collectionsRelay.accept(collections)
        }
    }

    init(baseService: MarketOverviewService) {
        self.baseService = baseService

        subscribe(disposeBag, baseService.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync()
    }

    private func sync(state: DataStatus<MarketOverviewService.Item>? = nil) {
        let state = state ?? baseService.state

        collections = state.data.map { item in
            item.marketOverview.collections[timePeriod] ?? []
        }
    }

}

extension MarketOverviewNftCollectionsService {

    var collectionsObservable: Observable<[NftCollection]?> {
        collectionsRelay.asObservable()
    }

}
