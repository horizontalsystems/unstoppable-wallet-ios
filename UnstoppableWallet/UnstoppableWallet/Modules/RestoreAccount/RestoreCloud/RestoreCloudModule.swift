import UIKit
import RxSwift
import MarketKit

struct RestoreCloudModule {

    static func viewController(returnViewController: UIViewController?) -> UIViewController {
        let service = RestoreCloudService(
                cloudAccountBackupManager: App.shared.cloudBackupManager,
                accountManager: App.shared.accountManager
        )
        let viewModel = RestoreCloudViewModel(service: service)
        return RestoreCloudViewController(viewModel: viewModel, returnViewController: returnViewController)
    }

    struct RestoredBackup: Codable {
        let name: String
        let walletBackup: WalletBackup

        enum CodingKeys: String, CodingKey {
            case name
            case walletBackup = "backup"
        }
    }

    struct DecryptedRestoredBackup {
        let name: String
        let walletBackup: WalletBackup
    }

    struct RestoredAccount {
        let name: String
        let accountType: AccountType
        let isManualBackedUp: Bool
        let isFileBackedUp: Bool
        let showSelectCoins: Bool
    }

}

extension RestoreCloudModule {
    enum RestoreError: Error {
        case emptyPassphrase
        case simplePassword
        case invalidPassword
        case invalidBackup
    }
}