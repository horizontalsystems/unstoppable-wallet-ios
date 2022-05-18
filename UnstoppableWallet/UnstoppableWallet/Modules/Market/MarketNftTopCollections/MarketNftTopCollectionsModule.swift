import UIKit
import ThemeKit
import MarketKit

struct MarketNftTopCollectionsModule {

    static func viewController() -> UIViewController {
        let service = MarketNftTopCollectionsService(provider: App.shared.hsNftProvider, currencyKit: App.shared.currencyKit)

        let decorator = MarketListNftCollectionDecorator(service: service)
        let viewModel = MarketNftTopCollectionsViewModel()
        let listViewModel = MarketListViewModel(service: service, decorator: decorator)
        let headerViewModel = NftCollectionsMultiSortHeaderViewModel(service: service, decorator: decorator)

        let viewController = MarketNftTopCollectionsViewController(viewModel: viewModel, listViewModel: listViewModel, headerViewModel: headerViewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

    enum SortType: Int, CaseIterable {
        case highestVolume
        case lowestVolume
        case topGainers
        case topLosers

        var title: String {
            switch self {
            case .highestVolume: return "market.top.highest_volume".localized
            case .lowestVolume: return "market.top.lowest_volume".localized
            case .topGainers: return "market.top.top_gainers".localized
            case .topLosers: return "market.top.top_losers".localized
            }
        }
    }

    static var selectorValues: [HsTimePeriod] {
        [HsTimePeriod.day1,
         HsTimePeriod.week1,
         HsTimePeriod.month1]
    }

}

extension Array where Element == NftCollection {

    func sorted(sortType: MarketNftTopCollectionsModule.SortType, timePeriod: HsTimePeriod) -> [NftCollection] {
        sorted { lhsCollection, rhsCollection in
            var lhsVolume: Decimal? = nil
            var rhsVolume: Decimal? = nil
            var lhsChange: Decimal? = nil
            var rhsChange: Decimal? = nil

            switch timePeriod {
            case .day1:
                lhsVolume = lhsCollection.stats.oneDayVolume?.value
                rhsVolume = rhsCollection.stats.oneDayVolume?.value

                lhsChange = lhsCollection.stats.oneDayChange
                rhsChange = rhsCollection.stats.oneDayChange
            case .week1:
                lhsVolume = lhsCollection.stats.sevenDayVolume?.value
                rhsVolume = rhsCollection.stats.sevenDayVolume?.value

                lhsChange = lhsCollection.stats.sevenDayChange
                rhsChange = rhsCollection.stats.sevenDayChange
            case .month1:
                lhsVolume = lhsCollection.stats.thirtyDayVolume?.value
                rhsVolume = rhsCollection.stats.thirtyDayVolume?.value

                lhsChange = lhsCollection.stats.thirtyDayChange
                rhsChange = rhsCollection.stats.thirtyDayChange
            default:
                break
            }

            switch sortType {
            case .highestVolume, .lowestVolume:
                guard let lhsVolume = lhsVolume else {
                    return true
                }
                guard let rhsVolume = rhsVolume else {
                    return false
                }

                return sortType == .highestVolume ? lhsVolume > rhsVolume : lhsVolume < rhsVolume
            case .topGainers, .topLosers:
                guard let lhsChange = lhsChange else {
                    return true
                }
                guard let rhsChange = rhsChange else {
                    return false
                }

                return sortType == .topGainers ? lhsChange > rhsChange : lhsChange < rhsChange
            }
        }
    }

}
