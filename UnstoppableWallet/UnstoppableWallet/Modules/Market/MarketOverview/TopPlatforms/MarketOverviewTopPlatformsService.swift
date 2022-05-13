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

    var timePeriod: TimePeriod = .day { didSet { syncState() } }

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
            Array(topPlatforms.sorted(sortType: .highestMarketCap, timePeriod: timePeriod).prefix(listCount))
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

extension MarketOverviewTopPlatformsService {

    enum SortType: Int, CaseIterable {
        case highestMarketCap
        case lowestMarketCap
        case topGainers
        case topLosers

        var title: String {
            switch self {
            case .highestMarketCap: return "market.top.highest_cap".localized
            case .lowestMarketCap: return "market.top.lowest_cap".localized
            case .topGainers: return "market.top.top_gainers".localized
            case .topLosers: return "market.top.top_losers".localized
            }
        }
    }

    enum TimePeriod: String, CaseIterable {
        case day
        case week
        case month

        var title: String {
            switch self {
            case .day: return "chart.time_duration.day".localized
            case .week: return "chart.time_duration.week".localized
            case .month: return "chart.time_duration.month".localized
            }
        }
    }

}

extension Array where Element == MarketKit.TopPlatform {

    func sorted(sortType: MarketOverviewTopPlatformsService.SortType, timePeriod: MarketOverviewTopPlatformsService.TimePeriod) -> [TopPlatform] {
        sorted { lhsPlatform, rhsPlatform in
            let lhsMarketCap = lhsPlatform.marketCap ?? 0
            let rhsMarketCap = rhsPlatform.marketCap ?? 0

            let lhsChange: Decimal
            let rhsChange: Decimal
            switch timePeriod {
            case .day:
                lhsChange = lhsPlatform.oneDayChange ?? 0
                rhsChange = rhsPlatform.oneDayChange ?? 0
            case .week:
                lhsChange = lhsPlatform.sevenDayChange ?? 0
                rhsChange = rhsPlatform.sevenDayChange ?? 0
            case .month:
                lhsChange = lhsPlatform.thirtyDayChange ?? 0
                rhsChange = rhsPlatform.thirtyDayChange ?? 0
            }

            switch sortType {
            case .highestMarketCap, .lowestMarketCap:
                return sortType == .highestMarketCap ? lhsMarketCap > rhsMarketCap : lhsMarketCap < rhsMarketCap
            case .topGainers, .topLosers:
                return sortType == .topGainers ? lhsChange > rhsChange : lhsChange < rhsChange
            }
        }
    }

}
