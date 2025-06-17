
import SwiftUI
import UIKit

enum ManageWalletsModule {
    static func viewController(account: Account) -> UIViewController {
        let (restoreSettingsService, restoreSettingsView) = RestoreSettingsModule.module(statPage: .coinManager)

        let service = ManageWalletsService(
            account: account,
            marketKit: Core.shared.marketKit,
            walletManager: Core.shared.walletManager,
            accountManager: Core.shared.accountManager,
            restoreSettingsService: restoreSettingsService
        )

        let viewModel = ManageWalletsViewModel(service: service)
        let viewController = ManageWalletsViewController(viewModel: viewModel, restoreSettingsView: restoreSettingsView)

        return ThemeNavigationController(rootViewController: viewController)
    }
}

struct ManageWalletsView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    let account: Account

    func makeUIViewController(context _: Context) -> UIViewController {
        ManageWalletsModule.viewController(account: account)
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
