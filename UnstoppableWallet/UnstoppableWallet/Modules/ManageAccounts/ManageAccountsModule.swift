import UIKit

struct ManageAccountsModule {

    static func viewController(mode: Mode, createAccountListener: ICreateAccountListener? = nil) -> UIViewController {
        let service = ManageAccountsService(accountManager: App.shared.accountManager)
        let viewModel = ManageAccountsViewModel(service: service, mode: mode)
        return ManageAccountsViewController(viewModel: viewModel, createAccountListener: createAccountListener)
    }

}

extension ManageAccountsModule {

    enum Mode {
        case manage
        case switcher
    }

}
