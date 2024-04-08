import MarketKit
import UIKit

enum CoinAuditsModule {
    static func viewController(audits: [Analytics.Audit]) -> UIViewController {
        let viewModel = CoinAuditsViewModel(items: audits)
        let urlManager = UrlManager(inApp: true)
        return CoinAuditsViewController(viewModel: viewModel, urlManager: urlManager)
    }
}
