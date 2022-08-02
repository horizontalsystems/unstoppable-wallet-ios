import Foundation
import RxSwift
import RxRelay
import CurrencyKit
import MarketKit

class MarketTopPlatformsService {
    typealias Item = TopPlatform

    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private var disposeBag = DisposeBag()
    private var syncDisposeBag = DisposeBag()

    var sortType: MarketTopPlatformsModule.SortType = .highestCap { didSet { syncIfPossible() } }
    var timePeriod: MarketKit.HsTimePeriod { didSet { syncIfPossible() } }

    private var internalState: MarketListServiceState<TopPlatform> = .loading

    private let stateRelay = BehaviorRelay<MarketListServiceState<TopPlatform>>(value: .loading)
    private(set) var state: MarketListServiceState<TopPlatform> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, appManager: IAppManager, timePeriod: HsTimePeriod) {
        self.marketKit = marketKit
        self.currencyKit = currencyKit
        self.timePeriod = timePeriod

        subscribe(disposeBag, currencyKit.baseCurrencyUpdatedObservable) { [weak self] _ in self?.sync() }
        subscribe(disposeBag, appManager.willEnterForegroundObservable) { [weak self] in self?.sync() }

        sync()
    }

    private func sync() {
        syncDisposeBag = DisposeBag()

        if case .failed = stateRelay.value {
            internalState = .loading
        }

        marketKit.topPlatformsSingle(currencyCode: currency.code)
                .subscribe(onSuccess: { [weak self] topPlatforms in
                    self?.internalState = .loaded(items: topPlatforms, softUpdate: false, reorder: false)

                    self?.sync(topPlatforms: topPlatforms)
                }, onError: { [weak self] error in
                    self?.internalState = .failed(error: error)
                })
                .disposed(by: syncDisposeBag)
    }

    private func sync(topPlatforms: [TopPlatform], reorder: Bool = false) {
        let sortType = sortType
        let timePeriod = timePeriod

        state = .loaded(items: topPlatforms.sorted(sortType: sortType, timePeriod: timePeriod), softUpdate: false, reorder: reorder)
    }

    private func syncIfPossible() {
        guard case .loaded(let platforms, _, _) = internalState else {
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

    var stateObservable: Observable<MarketListServiceState<TopPlatform>> {
        stateRelay.asObservable()
    }

    func refresh() {
        sync()
    }

}

extension MarketTopPlatformsService: IMarketListTopPlatformDecoratorService {

    var currency: Currency {
        currencyKit.baseCurrency
    }

}
