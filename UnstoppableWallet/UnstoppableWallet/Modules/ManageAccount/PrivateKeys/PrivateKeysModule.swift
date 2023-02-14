import UIKit

struct PrivateKeysModule {

    static func viewController(account: Account) -> UIViewController {
        let service = PrivateKeysService(account: account, pinKit: App.shared.pinKit)
        let viewModel = PrivateKeysViewModel(service: service)
        return PrivateKeysViewController(viewModel: viewModel)
    }

}
