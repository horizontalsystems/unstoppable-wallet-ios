import UIKit

struct ManageAccountsModule {

    static func viewController(mode: Mode) -> UIViewController {
        let service = ManageAccountsService(accountManager: App.shared.accountManager)
        let viewModel = ManageAccountsViewModel(service: service, mode: mode)
        return ManageAccountsViewController(viewModel: viewModel)
    }

}

extension ManageAccountsModule {

    enum Mode {
        case manage
        case switcher
    }

}
