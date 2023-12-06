import MarketKit
import ThemeKit
import UIKit

enum MarketTopPlatformsModule {
    static func viewController(timePeriod: HsTimePeriod) -> UIViewController {
        let service = MarketTopPlatformsService(marketKit: App.shared.marketKit, currencyManager: App.shared.currencyManager, appManager: App.shared.appManager, timePeriod: timePeriod)

        let decorator = MarketListTopPlatformDecorator(service: service)
        let viewModel = MarketTopPlatformsViewModel(service: service)
        let listViewModel = MarketListViewModel(service: service, decorator: decorator)
        let headerViewModel = TopPlatformsMultiSortHeaderViewModel(service: service, decorator: decorator)

        let viewController = MarketTopPlatformsViewController(viewModel: viewModel, listViewModel: listViewModel, headerViewModel: headerViewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

    enum SortType: Int, CaseIterable {
        case highestCap
        case lowestCap
        case topGainers
        case topLosers

        var title: String {
            switch self {
            case .highestCap: return "market.top.highest_cap".localized
            case .lowestCap: return "market.top.lowest_cap".localized
            case .topGainers: return "market.top.top_gainers".localized
            case .topLosers: return "market.top.top_losers".localized
            }
        }
    }

    static var selectorValues: [HsTimePeriod] {
        [
            HsTimePeriod.week1,
            HsTimePeriod.month1,
            HsTimePeriod.month3,
        ]
    }
}

extension [MarketKit.TopPlatform] {
    func sorted(sortType: MarketTopPlatformsModule.SortType, timePeriod: HsTimePeriod) -> [TopPlatform] {
        sorted { lhsPlatform, rhsPlatform in
            let lhsCap = lhsPlatform.marketCap
            let rhsCap = rhsPlatform.marketCap

            let lhsChange = lhsPlatform.changes[timePeriod]
            let rhsChange = rhsPlatform.changes[timePeriod]

            switch sortType {
            case .highestCap, .lowestCap:
                guard let lhsCap else {
                    return true
                }
                guard let rhsCap else {
                    return false
                }

                return sortType == .highestCap ? lhsCap > rhsCap : lhsCap < rhsCap
            case .topGainers, .topLosers:
                guard let lhsChange else {
                    return true
                }
                guard let rhsChange else {
                    return false
                }

                return sortType == .topGainers ? lhsChange > rhsChange : lhsChange < rhsChange
            }
        }
    }
}
