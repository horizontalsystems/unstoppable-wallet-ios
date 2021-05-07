import UIKit

struct BackupConfirmKeyModule {

    static func viewController(account: Account) -> UIViewController? {
        guard let service = BackupConfirmKeyService(account: account, accountManager: App.shared.accountManager, appManager: App.shared.appManager) else {
            return nil
        }
        let viewModel = BackupConfirmKeyViewModel(service: service)
        return BackupConfirmKeyViewController(viewModel: viewModel)
    }

}
