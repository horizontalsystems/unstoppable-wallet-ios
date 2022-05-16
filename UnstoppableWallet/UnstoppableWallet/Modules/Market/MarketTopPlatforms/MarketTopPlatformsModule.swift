import UIKit
import ThemeKit
import MarketKit

struct MarketTopPlatformsModule {

    static func viewController() -> UIViewController {
        let service = MarketTopPlatformsService(marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit, appManager: App.shared.appManager)

        let decorator = MarketListTopPlatformDecorator(service: service)
        let viewModel = MarketTopPlatformsViewModel()
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

}

extension Array where Element == MarketKit.TopPlatform {

    func sorted(sortType: MarketTopPlatformsModule.SortType, timePeriod: HsTimePeriod) -> [TopPlatform] {
        sorted { lhsPlatform, rhsPlatform in
            let lhsCap = lhsPlatform.marketCap ?? 0
            let rhsCap = rhsPlatform.marketCap ?? 0

            let lhsChange: Decimal
            let rhsChange: Decimal

            switch timePeriod {
            case .day1:
                lhsChange = lhsPlatform.oneDayChange ?? 0
                rhsChange = rhsPlatform.oneDayChange ?? 0
            case .week1:
                lhsChange = lhsPlatform.sevenDayChange ?? 0
                rhsChange = rhsPlatform.sevenDayChange ?? 0
            case .month1:
                lhsChange = lhsPlatform.thirtyDayChange ?? 0
                rhsChange = rhsPlatform.thirtyDayChange ?? 0
            default:
                lhsChange = 0
                rhsChange = 0
                print("unreachable state")
            }

            switch sortType {
            case .highestCap, .lowestCap:
                return sortType == .highestCap ? lhsCap > rhsCap : lhsCap < rhsCap
            case .topGainers, .topLosers:
                return sortType == .topGainers ? lhsChange > rhsChange : lhsChange < rhsChange
            }
        }
    }

}
