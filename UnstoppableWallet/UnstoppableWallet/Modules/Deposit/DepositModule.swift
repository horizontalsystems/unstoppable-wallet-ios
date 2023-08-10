import UIKit
import ThemeKit

struct DepositModule {

    static func viewController(wallet: Wallet) -> UIViewController? {
        let service = DepositService(wallet: wallet, adapterManager: App.shared.adapterManager)
        let depositViewItemHelperFactory = DepositAddressViewHelperFactory(wallet: wallet)

        let viewModel = DepositViewModel(service: service, depositViewItemHelperFactory: depositViewItemHelperFactory)
        let viewController = DepositViewController(viewModel: viewModel)

        return viewController
    }

}
