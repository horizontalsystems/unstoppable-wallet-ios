import UIKit

struct CoinMajorHoldersModule {

    static func viewController(coinUid: String) -> UIViewController {
        let service = CoinMajorHoldersService(coinUid: coinUid, marketKit: App.shared.marketKit)
        let viewModel = CoinMajorHoldersViewModel(service: service)
        let urlManager = UrlManager(inApp: true)
        return CoinMajorHoldersViewController(viewModel: viewModel, urlManager: urlManager)
    }

}
