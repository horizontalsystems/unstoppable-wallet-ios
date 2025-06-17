import UIKit

enum PrivateKeysModule {
    static func viewController(account: Account) -> UIViewController {
        let service = PrivateKeysService(account: account, passcodeManager: Core.shared.passcodeManager)
        let viewModel = PrivateKeysViewModel(service: service)
        return PrivateKeysViewController(viewModel: viewModel)
    }
}
