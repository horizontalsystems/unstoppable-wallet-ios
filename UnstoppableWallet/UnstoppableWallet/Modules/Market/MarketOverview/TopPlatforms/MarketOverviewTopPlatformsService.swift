import Foundation
import RxSwift
import RxRelay
import CurrencyKit
import MarketKit

class MarketOverviewTopPlatformsService {
    private let listCount = 5

    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private var disposeBag = DisposeBag()
    private var syncDisposeBag = DisposeBag()

    var timePeriod: HsTimePeriod = .day1 { didSet { syncState() } }

    private var internalStatus: DataStatus<[TopPlatform]> = .loading {
        didSet {
            syncState()
        }
    }

    private let statusRelay = BehaviorRelay<DataStatus<[TopPlatform]>>(value: .loading)

    init(marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, appManager: IAppManager) {
        self.marketKit = marketKit
        self.currencyKit = currencyKit

        subscribe(disposeBag, currencyKit.baseCurrencyUpdatedObservable) { [weak self] _ in self?.syncInternalState() }
        subscribe(disposeBag, appManager.willEnterForegroundObservable) { [weak self] in self?.syncInternalState() }

        syncInternalState()
    }

    private func syncInternalState() {
        syncDisposeBag = DisposeBag()

        if case .failed = statusRelay.value {
            internalStatus = .loading
        }

        marketKit.topPlatformsSingle(currencyCode: currency.code)
                .subscribe(onSuccess: { [weak self] topPlatforms in
                    self?.internalStatus = .completed(topPlatforms)
                }, onError: { [weak self] error in
                    self?.internalStatus = .failed(error)
                })
                .disposed(by: syncDisposeBag)
    }

    private func syncState() {
        let timePeriod = timePeriod
        let listCount = listCount

        return statusRelay.accept(internalStatus.map { topPlatforms in
            Array(topPlatforms.sorted(sortType: .highestCap, timePeriod: timePeriod).prefix(listCount))
        })
    }

    private func syncIfPossible() {
        guard case .completed = internalStatus else {
            return
        }

        syncState()
    }

}

extension MarketOverviewTopPlatformsService {

    var stateObservable: Observable<DataStatus<[TopPlatform]>> {
        statusRelay.asObservable()
    }

    func refresh() {
        syncInternalState()
    }

}

extension MarketOverviewTopPlatformsService: IMarketListTopPlatformDecoratorService {

    var currency: Currency {
        currencyKit.baseCurrency
    }

}
