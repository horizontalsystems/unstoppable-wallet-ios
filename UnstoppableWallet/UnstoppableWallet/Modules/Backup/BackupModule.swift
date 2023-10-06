import UIKit
import ThemeKit

struct BackupModule {

    static func manualViewController(account: Account, onComplete: (() -> ())? = nil) -> UIViewController? {
        guard let service = BackupService(account: account) else {
            return nil
        }
        let viewModel = BackupViewModel(service: service)
        let viewController = BackupViewController(viewModel: viewModel)
        viewController.onComplete = onComplete

        return ThemeNavigationController(rootViewController: viewController)
    }

    static func cloudViewController(account: Account) -> UIViewController {
        let service = ICloudBackupTermsService(cloudAccountBackupManager: App.shared.cloudBackupManager, account: account)
        let viewModel = ICloudBackupTermsViewModel(service: service)
        let viewController = ICloudBackupTermsViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}

extension BackupModule {
    enum Source {
        case wallet(WalletBackup)
        case full(FullBackup)

        enum Abstract {
            case wallet
            case full
        }

        var id: String {
            switch self {
            case let .wallet(backup): return backup.id
            case let .full(backup): return backup.id
            }
        }

        var timestamp: TimeInterval? {
            switch self {
            case let .wallet(backup): return backup.timestamp
            case let .full(backup): return backup.timestamp
            }
        }
    }

    struct NamedSource {
        let name: String
        let source: Source
    }
}