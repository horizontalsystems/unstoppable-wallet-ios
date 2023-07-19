import UIKit
import ThemeKit

struct CoinRankModule {

    static func viewController(type: RankType) -> UIViewController {
        let service = CoinRankService(
                type: type,
                marketKit: App.shared.marketKit,
                currencyKit: App.shared.currencyKit
        )

        let viewModel = CoinRankViewModel(service: service)
        let viewController = CoinRankViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}

extension CoinRankModule {

    enum RankType {
        case cexVolume
        case dexVolume
        case dexLiquidity
        case address
        case txCount
        case holders
        case fee
        case revenue
    }

}
