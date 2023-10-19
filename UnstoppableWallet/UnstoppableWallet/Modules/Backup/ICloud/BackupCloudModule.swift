import UIKit
import ThemeKit
import HsToolKit

class BackupCloudModule {
    static let minimumPassphraseLength = 8

    static func backupTerms(account: Account) -> UIViewController {
        let service = ICloudBackupTermsService(cloudAccountBackupManager: App.shared.cloudBackupManager, account: account)
        let viewModel = ICloudBackupTermsViewModel(service: service)
        let controller = ICloudBackupTermsViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: controller)
    }

    static func backupName(account: Account) -> UIViewController {
        let service = ICloudBackupNameService(iCloudManager: App.shared.cloudBackupManager, account: account)
        let viewModel = ICloudBackupNameViewModel(service: service)
        let controller = ICloudBackupNameViewController(viewModel: viewModel)

        return controller
    }

    static func backupPassword(account: Account, name: String) -> UIViewController {
        let service = BackupCloudPassphraseService(iCloudManager: App.shared.cloudBackupManager, account: account, name: name)
        let viewModel = BackupCloudPassphraseViewModel(service: service)
        let controller = BackupCloudPassphraseViewController(viewModel: viewModel)

        return controller
    }

}

extension BackupCloudModule {

    enum PassphraseCharacterSet: CaseIterable {
        case lowerCased
        case upperCased
        case digits
        case customSymbols

        var set: CharacterSet {
            switch self {
            case .upperCased: return CharacterSet.uppercaseLetters
            case .lowerCased: return CharacterSet.lowercaseLetters
            case .digits: return CharacterSet.decimalDigits
            case .customSymbols: return CharacterSet(charactersIn: " '\"`&/?!:;.,~*$=+-[](){}<>\\_#@|%")
            }
        }

        func contains(_ string: String) -> Bool {
            string.rangeOfCharacter(from: set) != nil
        }
    }

}