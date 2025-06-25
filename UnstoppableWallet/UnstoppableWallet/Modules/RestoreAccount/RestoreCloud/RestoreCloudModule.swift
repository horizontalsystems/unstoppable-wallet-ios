import MarketKit
import RxSwift
import UIKit

enum RestoreCloudModule {
    static func viewController(sourceType: BackupModule.Source.Abstract, onRestore: @escaping () -> Void) -> UIViewController {
        let service = RestoreCloudService(
            cloudAccountBackupManager: Core.shared.cloudBackupManager,
            accountManager: Core.shared.accountManager
        )
        let viewModel = RestoreCloudViewModel(service: service, sourceType: sourceType)
        return RestoreCloudViewController(viewModel: viewModel, onRestore: onRestore)
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
