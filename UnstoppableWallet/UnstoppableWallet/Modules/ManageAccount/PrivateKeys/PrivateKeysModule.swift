import UIKit

struct PrivateKeysModule {
    static func viewController(account: Account) -> UIViewController {
        let service = PrivateKeysService(account: account, passcodeManager: App.shared.passcodeManager)
        let viewModel = PrivateKeysViewModel(service: service)
        return PrivateKeysViewController(viewModel: viewModel)
    }
}
