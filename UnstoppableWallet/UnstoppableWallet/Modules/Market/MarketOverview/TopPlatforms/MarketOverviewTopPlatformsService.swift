import Combine
import Foundation
import MarketKit
import RxRelay
import RxSwift

class MarketOverviewTopPlatformsService {
    private let baseService: MarketOverviewService
    private var cancellables = Set<AnyCancellable>()

    var timePeriod: HsTimePeriod = .week1 {
        didSet {
            sync()
        }
    }

    private let topPlatformsRelay = PublishRelay<[TopPlatform]?>()
    private(set) var topPlatforms: [TopPlatform]? {
        didSet {
            topPlatformsRelay.accept(topPlatforms)
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

        topPlatforms = state.data.map { item in
            item.marketOverview.topPlatforms
        }
    }
}

extension MarketOverviewTopPlatformsService {
    var topPlatformsObservable: Observable<[TopPlatform]?> {
        topPlatformsRelay.asObservable()
    }
}

extension MarketOverviewTopPlatformsService: IMarketListTopPlatformDecoratorService {
    var currency: Currency {
        baseService.currency
    }
}
