import UIKit
import ThemeKit
import MarketKit

struct MarketNftTopCollectionsModule {

    static func viewController(timePeriod: HsTimePeriod) -> UIViewController {
        let service = MarketNftTopCollectionsService(marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit, timePeriod: timePeriod)

        let decorator = MarketListNftCollectionDecorator(service: service)
        let viewModel = MarketNftTopCollectionsViewModel()
        let listViewModel = MarketListViewModel(service: service, decorator: decorator, itemLimit: 100)
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
            let lhsVolume = lhsCollection.stats.volumes[timePeriod]?.value
            let rhsVolume = rhsCollection.stats.volumes[timePeriod]?.value

            let lhsChange = lhsCollection.stats.changes[timePeriod]
            let rhsChange = rhsCollection.stats.changes[timePeriod]

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
