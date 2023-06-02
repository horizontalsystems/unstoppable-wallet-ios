import UIKit
import RxSwift
import MarketKit

struct RestoreCloudModule {

    static func viewController(returnViewController: UIViewController?) -> UIViewController {
        let service = RestoreCloudService(
                cloudAccountBackupManager: App.shared.cloudAccountBackupManager,
                accountManager: App.shared.accountManager
        )
        let viewModel = RestoreCloudViewModel(service: service)
        return RestoreCloudViewController(viewModel: viewModel, returnViewController: returnViewController)
    }

    struct RestoredBackup {
        let name: String
        let walletBackup: WalletBackup
    }

    struct RestoredAccount {
        let name: String
        let accountType: AccountType
        let isManualBackedUp: Bool
    }

}
