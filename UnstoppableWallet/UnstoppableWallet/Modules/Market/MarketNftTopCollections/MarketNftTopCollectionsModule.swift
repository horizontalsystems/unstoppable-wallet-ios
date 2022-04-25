import UIKit
import ThemeKit

struct MarketNftTopCollectionsModule {

    static func viewController() -> UIViewController {
        let service = MarketNftTopCollectionsService(provider: App.shared.hsNftProvider, currencyKit: App.shared.currencyKit)

        let decorator = MarketListNftCollectionDecorator()
        let viewModel = MarketNftTopCollectionsViewModel(service: service)
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

    enum VolumeRange: Int, CaseIterable {
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

extension Array where Element == NftCollection {

    func sorted(sortType: MarketNftTopCollectionsModule.SortType, volumeRange: MarketNftTopCollectionsModule.VolumeRange) -> [NftCollection] {
        sorted { lhsCollection, rhsCollection in
            let lhsVolume: Decimal
            let rhsVolume: Decimal
            switch volumeRange {
            case .day:
                lhsVolume = lhsCollection.stats.oneDayVolume?.value ?? 0
                rhsVolume = rhsCollection.stats.oneDayVolume?.value ?? 0
            case .week:
                lhsVolume = lhsCollection.stats.sevenDayVolume?.value ?? 0
                rhsVolume = rhsCollection.stats.sevenDayVolume?.value ?? 0
            case .month:
                lhsVolume = lhsCollection.stats.thirtyDayVolume?.value ?? 0
                rhsVolume = rhsCollection.stats.thirtyDayVolume?.value ?? 0
            }

            let lhsChange: Decimal
            let rhsChange: Decimal
            switch volumeRange {
            case .day:
                lhsChange = lhsCollection.stats.oneDayChange ?? 0
                rhsChange = rhsCollection.stats.oneDayChange ?? 0
            case .week:
                lhsChange = lhsCollection.stats.sevenDayChange ?? 0
                rhsChange = rhsCollection.stats.sevenDayChange ?? 0
            case .month:
                lhsChange = lhsCollection.stats.thirtyDayChange ?? 0
                rhsChange = rhsCollection.stats.thirtyDayChange ?? 0
            }

            switch sortType {
            case .highestVolume, .lowestVolume:
                return sortType == .highestVolume ? lhsVolume > rhsVolume : lhsVolume < rhsVolume
            case .topGainers, .topLosers:
                return sortType == .topGainers ? lhsChange > rhsChange : lhsChange < rhsChange
            }
        }
    }

}
