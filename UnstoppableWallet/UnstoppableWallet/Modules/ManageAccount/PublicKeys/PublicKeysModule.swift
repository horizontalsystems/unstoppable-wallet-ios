import UIKit

struct PublicKeysModule {

    static func viewController(account: Account) -> UIViewController {
        let service = PublicKeysService(account: account)
        let viewModel = PublicKeysViewModel(service: service)
        return PublicKeysViewController(viewModel: viewModel)
    }

}
