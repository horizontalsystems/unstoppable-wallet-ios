import UIKit

struct BackupVerifyWordsModule {

    static func viewController(account: Account) -> UIViewController? {
        guard let service = BackupVerifyWordsService(account: account, accountManager: App.shared.accountManager, appManager: App.shared.appManager) else {
            return nil
        }
        let viewModel = BackupVerifyWordsViewModel(service: service)
        return BackupVerifyWordsViewController(viewModel: viewModel)
    }

}
