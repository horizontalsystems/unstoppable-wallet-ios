import UIKit

class BackupRequiredRouter {
    private let account: Account
    private let predefinedAccountType: PredefinedAccountType
    private weak var sourceViewController: UIViewController?

    init(account: Account, predefinedAccountType: PredefinedAccountType, sourceViewController: UIViewController?) {
        self.account = account
        self.predefinedAccountType = predefinedAccountType
        self.sourceViewController = sourceViewController
    }

    func showBackup() {
        sourceViewController?.present(BackupRouter.module(account: account, predefinedAccountType: predefinedAccountType), animated: true)
    }

}

extension BackupRequiredRouter {

    static func module(account: Account, predefinedAccountType: PredefinedAccountType, sourceViewController: UIViewController?, text: String) -> UIViewController {
        let router = BackupRequiredRouter(account: account, predefinedAccountType: predefinedAccountType, sourceViewController: sourceViewController)

        let viewController = BackupRequiredViewController(
                router: router,
                subtitle: predefinedAccountType.title,
                text: text
        )

        return viewController.toBottomSheet
    }

}
