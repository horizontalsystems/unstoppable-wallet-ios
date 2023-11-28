import Combine
import Foundation
import HsExtensions
import MarketKit
import RxRelay
import RxSwift

class MarketTopPlatformsService {
    typealias Item = TopPlatform

    private let marketKit: MarketKit.Kit
    private let currencyManager: CurrencyManager
    private var disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()
    private var tasks = Set<AnyTask>()

    var sortType: MarketTopPlatformsModule.SortType = .highestCap { didSet { syncIfPossible() } }
    var timePeriod: MarketKit.HsTimePeriod { didSet { syncIfPossible() } }

    private var internalState: MarketListServiceState<TopPlatform> = .loading

    @PostPublished private(set) var state: MarketListServiceState<TopPlatform> = .loading

    init(marketKit: MarketKit.Kit, currencyManager: CurrencyManager, appManager: IAppManager, timePeriod: HsTimePeriod) {
        self.marketKit = marketKit
        self.currencyManager = currencyManager
        self.timePeriod = timePeriod

        currencyManager.$baseCurrency
            .sink { [weak self] _ in
                self?.sync()
            }
            .store(in: &cancellables)

        subscribe(disposeBag, appManager.willEnterForegroundObservable) { [weak self] in self?.sync() }

        sync()
    }

    private func sync() {
        tasks = Set()

        if case .failed = state {
            internalState = .loading
        }

        Task { [weak self, marketKit, currency] in
            do {
                let topPlatforms = try await marketKit.topPlatforms(currencyCode: currency.code)
                self?.internalState = .loaded(items: topPlatforms, softUpdate: false, reorder: false)
                self?.sync(topPlatforms: topPlatforms)
            } catch {
                self?.internalState = .failed(error: error)
            }
        }.store(in: &tasks)
    }

    private func sync(topPlatforms: [TopPlatform], reorder: Bool = false) {
        let sortType = sortType
        let timePeriod = timePeriod

        state = .loaded(items: topPlatforms.sorted(sortType: sortType, timePeriod: timePeriod), softUpdate: false, reorder: reorder)
    }

    private func syncIfPossible() {
        guard case let .loaded(platforms, _, _) = internalState else {
            return
        }

        sync(topPlatforms: platforms, reorder: true)
    }
}

extension MarketTopPlatformsService {
    var topPlatforms: [TopPlatform]? {
        if case let .loaded(data, _, _) = state {
            return data
        }

        return nil
    }
}

extension MarketTopPlatformsService: IMarketListService {
    var statePublisher: AnyPublisher<MarketListServiceState<Item>, Never> {
        $state
    }

    func refresh() {
        sync()
    }
}

extension MarketTopPlatformsService: IMarketListTopPlatformDecoratorService {
    var currency: Currency {
        currencyManager.baseCurrency
    }
}
