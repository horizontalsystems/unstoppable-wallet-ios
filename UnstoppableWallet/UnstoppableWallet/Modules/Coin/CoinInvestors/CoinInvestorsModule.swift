import UIKit

enum CoinInvestorsModule {
    static func viewController(coinUid: String) -> UIViewController {
        let service = CoinInvestorsService(coinUid: coinUid, marketKit: App.shared.marketKit, currencyManager: App.shared.currencyManager)
        let viewModel = CoinInvestorsViewModel(service: service)
        return CoinInvestorsViewController(viewModel: viewModel, urlManager: UrlManager(inApp: true))
    }
}
