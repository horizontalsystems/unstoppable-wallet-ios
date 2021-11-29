import UIKit

struct CoinInvestorsModule {

    static func viewController(coinUid: String) -> UIViewController {
        let service = CoinInvestorsService(coinUid: coinUid, marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit)
        let viewModel = CoinInvestorsViewModel(service: service)
        return CoinInvestorsViewController(viewModel: viewModel, urlManager: UrlManager(inApp: true))
    }

}
