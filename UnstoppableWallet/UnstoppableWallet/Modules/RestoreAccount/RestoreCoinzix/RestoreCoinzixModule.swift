import UIKit

struct RestoreCoinzixModule {

    static func viewController(returnViewController: UIViewController?) -> UIViewController? {
        guard let hCaptchaKey = App.shared.appConfigProvider.coinzixHCaptchaKey else {
            return nil
        }

        let service = RestoreCoinzixService(
            networkManager: App.shared.networkManager,
            accountFactory: App.shared.accountFactory,
            accountManager: App.shared.accountManager
        )
        let viewModel = RestoreCoinzixViewModel(service: service)

        return RestoreCoinzixViewController(hCaptchaKey: hCaptchaKey, viewModel: viewModel, returnViewController: returnViewController)
    }

}
