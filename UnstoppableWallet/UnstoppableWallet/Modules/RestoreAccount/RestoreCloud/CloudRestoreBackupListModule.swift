import MarketKit
import RxSwift
import UIKit

enum CloudRestoreBackupListModule {
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

extension CloudRestoreBackupListModule {
    enum RestoreError: Error {
        case emptyPassphrase
        case simplePassword
        case invalidPassword
        case invalidBackup
    }
}
