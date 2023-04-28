import Foundation
import Combine
import RxSwift
import RxRelay
import CurrencyKit
import MarketKit

class MarketOverviewNftCollectionsService: IMarketListNftTopCollectionDecoratorService {
    private let baseService: MarketOverviewService
    private var cancellables = Set<AnyCancellable>()

    var timePeriod: HsTimePeriod = .week1 {
        didSet {
            sync()
        }
    }

    private let collectionsRelay = PublishRelay<[NftTopCollection]?>()
    private(set) var collections: [NftTopCollection]? {
        didSet {
            collectionsRelay.accept(collections)
        }
    }

    init(baseService: MarketOverviewService) {
        self.baseService = baseService

        baseService.$state
                .sink { [weak self] in self?.sync(state: $0) }
                .store(in: &cancellables)

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

    var collectionsObservable: Observable<[NftTopCollection]?> {
        collectionsRelay.asObservable()
    }

    func topCollection(uid: String) -> NftTopCollection? {
        guard let collections = collections else {
            return nil
        }

        return collections.first { $0.uid == uid }
    }

}
