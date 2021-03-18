import UIKit
import ThemeKit
import XRatesKit

struct CoinInvestorsModule {

    static func viewController(coinCode: String, fundCategories: [CoinFundCategory]) -> UIViewController {
        let viewModel = CoinInvestorsViewModel(coinCode: coinCode, fundCategories: fundCategories)
        return CoinInvestorsViewController(viewModel: viewModel, urlManager: UrlManager(inApp: true))
    }

}
