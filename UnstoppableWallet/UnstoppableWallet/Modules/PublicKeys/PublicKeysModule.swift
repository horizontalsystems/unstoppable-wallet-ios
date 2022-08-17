import UIKit
import ThemeKit

struct PublicKeysModule {

    static func viewController(account: Account) -> UIViewController? {
        guard let service = PublicKeysService(account: account, evmBlockchainManager: App.shared.evmBlockchainManager) else {
            return nil
        }

        let viewModel = PublicKeysViewModel(service: service)
        let viewController = PublicKeysViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
