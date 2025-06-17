import UIKit

enum BackupVerifyWordsModule {
    static func viewController(account: Account, onComplete: (() -> Void)? = nil) -> UIViewController? {
        guard let service = BackupVerifyWordsService(account: account, accountManager: Core.shared.accountManager, appManager: Core.shared.appManager) else {
            return nil
        }
        let viewModel = BackupVerifyWordsViewModel(service: service)
        let viewController = BackupVerifyWordsViewController(viewModel: viewModel)
        viewController.onComplete = onComplete

        return viewController
    }
}
