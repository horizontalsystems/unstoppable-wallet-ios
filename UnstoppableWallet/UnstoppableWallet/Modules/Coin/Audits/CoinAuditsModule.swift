import UIKit
import CoinKit

struct CoinAuditsModule {

    static func viewController(coinType: CoinType) -> UIViewController {
        let service = CoinAuditsService(coinType: coinType, rateManager: App.shared.rateManager)
        let viewModel = CoinAuditsViewModel(service: service)
        let urlManager = UrlManager(inApp: true)
        return CoinAuditsViewController(viewModel: viewModel, urlManager: urlManager)
    }

}
