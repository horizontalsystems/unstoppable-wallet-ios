import UIKit

struct RestoreCoinzixModule {

    static func viewController(returnViewController: UIViewController?) -> UIViewController {
        let service = RestoreCoinzixService(networkManager: App.shared.networkManager)
        let viewModel = RestoreCoinzixViewModel(service: service)

        return RestoreCoinzixViewController(viewModel: viewModel, returnViewController: returnViewController)
    }

}
