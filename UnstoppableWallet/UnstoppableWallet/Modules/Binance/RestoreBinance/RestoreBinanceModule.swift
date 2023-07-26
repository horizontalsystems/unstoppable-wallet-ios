import UIKit

struct RestoreBinanceModule {

    static func viewController(returnViewController: UIViewController?) -> UIViewController {
        let service = RestoreBinanceService(
                networkManager: App.shared.networkManager,
                accountFactory: App.shared.accountFactory,
                accountManager: App.shared.accountManager
        )
        let viewModel = RestoreBinanceViewModel(service: service)

        return RestoreBinanceViewController(viewModel: viewModel, returnViewController: returnViewController)
    }

}
