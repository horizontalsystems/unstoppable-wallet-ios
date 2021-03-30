import UIKit

struct ManageAccountsModuleNew {

    static func viewController() -> UIViewController {
        let service = ManageAccountsServiceNew(accountManager: App.shared.accountManager)
        let viewModel = ManageAccountsViewModelNew(service: service)
        return ManageAccountsViewControllerNew(viewModel: viewModel)
    }

}
