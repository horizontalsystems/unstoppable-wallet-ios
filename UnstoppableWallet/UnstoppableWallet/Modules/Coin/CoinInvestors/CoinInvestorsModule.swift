import UIKit
import ThemeKit
import XRatesKit

struct CoinInvestorsModule {

    static func viewController(fundCategories: [CoinFundCategory]) -> UIViewController {
        let viewModel = CoinInvestorsViewModel(fundCategories: fundCategories)
        return CoinInvestorsViewController(viewModel: viewModel, urlManager: UrlManager(inApp: true))
    }

}
