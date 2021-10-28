import UIKit

struct CoinAuditsModule {

    static func viewController(addresses: [String]) -> UIViewController {
        let service = CoinAuditsService(addresses: addresses, marketKit: App.shared.marketKit)
        let viewModel = CoinAuditsViewModel(service: service)
        let urlManager = UrlManager(inApp: true)
        return CoinAuditsViewController(viewModel: viewModel, urlManager: urlManager)
    }

}
