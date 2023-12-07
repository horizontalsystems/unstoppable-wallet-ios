import SwiftUI
import ThemeKit
import UIKit

enum BackupModule {
    static func manualViewController(account: Account, onComplete: (() -> Void)? = nil) -> UIViewController? {
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

struct BackupView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    private let account: Account
    private let onComplete: (() -> Void)?

    init(account: Account, onComplete: (() -> Void)? = nil) {
        self.account = account
        self.onComplete = onComplete
    }

    func makeUIViewController(context _: Context) -> UIViewController {
        BackupModule.manualViewController(account: account, onComplete: onComplete) ?? UIViewController()
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}

struct ICloudBackupTermsView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    private let account: Account

    init(account: Account) {
        self.account = account
    }

    func makeUIViewController(context _: Context) -> UIViewController {
        BackupModule.cloudViewController(account: account)
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
