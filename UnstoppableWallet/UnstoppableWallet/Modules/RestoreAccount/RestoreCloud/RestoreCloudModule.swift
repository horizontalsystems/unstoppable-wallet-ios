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

    struct Item {
        let name: String
        let walletBackup: WalletBackup
    }

}
