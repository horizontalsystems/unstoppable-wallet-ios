import UIKit

struct CoinMajorHoldersModule {

    static func viewController(address: String) -> UIViewController {
        let service = CoinMajorHoldersService(address: address, marketKit: App.shared.marketKit)
        let viewModel = CoinMajorHoldersViewModel(service: service)
        let urlManager = UrlManager(inApp: true)
        return CoinMajorHoldersViewController(viewModel: viewModel, urlManager: urlManager)
    }

}
