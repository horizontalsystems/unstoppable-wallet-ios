import UIKit

struct BackupVerifyWordsModule {

    static func viewController(account: Account, onComplete: (() -> ())? = nil) -> UIViewController? {
        guard let service = BackupVerifyWordsService(account: account, accountManager: App.shared.accountManager, appManager: App.shared.appManager) else {
            return nil
        }
        let viewModel = BackupVerifyWordsViewModel(service: service)
        let viewController = BackupVerifyWordsViewController(viewModel: viewModel)
        viewController.onComplete = onComplete

        return viewController
    }

}
