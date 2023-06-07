import UIKit
import ThemeKit

struct DepositModule {

    static func viewController(wallet: Wallet) -> UIViewController? {
        guard let depositAdapter = App.shared.adapterManager.depositAdapter(for: wallet) else {
            return nil
        }

        let depositViewItemHelper: DepositAddressViewHelper
        if let derivation = wallet.coinSettings.derivation {                                            // has mnemonic typed wallet
            depositViewItemHelper = DepositAddressViewHelper.Derivation(
                    testNet: !depositAdapter.isMainNet,
                    mnemonicDerivation: derivation)
        } else if let depositAddress = depositAdapter.receiveAddress as? ActivatedDepositAddress {      // has activated address
            depositViewItemHelper = DepositAddressViewHelper.Activated(
                    testNet: !depositAdapter.isMainNet,
                    isActive: depositAddress.isActive)
        } else {
            depositViewItemHelper = DepositAddressViewHelper(testNet: !depositAdapter.isMainNet)
        }

        let service = DepositService(wallet: wallet, adapter: depositAdapter)
        let viewModel = DepositViewModel(service: service, depositViewItemHelper: depositViewItemHelper)
        let viewController = DepositViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
