import UIKit
import ThemeKit

struct DepositModule {

    static func viewController(wallet: WalletNew) -> UIViewController? {
        guard let depositAdapter = App.shared.adapterManagerNew.depositAdapter(for: wallet) else {
            return nil
        }

        let service = DepositService(wallet: wallet, adapter: depositAdapter)
        let viewModel = DepositViewModel(service: service)
        let viewController = DepositViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
