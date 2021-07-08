import UIKit
import CoinKit

struct CoinMajorHoldersModule {

    static func viewController(coinType: CoinType) -> UIViewController {
        let service = CoinMajorHoldersService(coinType: coinType, rateManager: App.shared.rateManager)
        let viewModel = CoinMajorHoldersViewModel(service: service)
        let urlManager = UrlManager(inApp: true)
        return CoinMajorHoldersViewController(viewModel: viewModel, urlManager: urlManager)
    }

}
