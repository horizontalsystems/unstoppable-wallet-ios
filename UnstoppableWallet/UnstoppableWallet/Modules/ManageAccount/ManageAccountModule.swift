import UIKit

struct ManageAccountModule {

    static func viewController(accountId: String) -> UIViewController? {
        guard let service = ManageAccountService(accountId: accountId, accountManager: App.shared.accountManager) else {
            return nil
        }

        let viewModel = ManageAccountViewModel(service: service)
        return ManageAccountViewController(viewModel: viewModel)
    }

}
