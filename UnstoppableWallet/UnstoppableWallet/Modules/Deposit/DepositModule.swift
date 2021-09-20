import UIKit
import ThemeKit

struct DepositModule {

    static func viewController(wallet: Wallet) -> UIViewController? {
        guard let depositAdapter = App.shared.adapterManager.depositAdapter(for: wallet) else {
            return nil
        }

        let service = DepositService(wallet: wallet, adapter: depositAdapter)
        let viewModel = DepositViewModel(service: service)
        let viewController = DepositViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
