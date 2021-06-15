import UIKit
import ThemeKit

struct DepositModule {

    static func viewController(wallet: Wallet) -> UIViewController? {
        guard let activeWallet = App.shared.walletManager.activeWallet(wallet: wallet), let depositAdapter = activeWallet.depositAdapter else {
            return nil
        }

        let service = DepositService(activeWallet: activeWallet, depositAdapter: depositAdapter)
        let viewModel = DepositViewModel(service: service)
        let viewController = DepositViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
