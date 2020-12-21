import UIKit
import ThemeKit

struct CreateWalletModule {

    static func start(mode: ModuleStartMode, predefinedAccountType: PredefinedAccountType? = nil, onComplete: (() -> ())? = nil) {
        let service = CreateWalletService(
                predefinedAccountType: predefinedAccountType,
                coinManager: App.shared.coinManager,
                accountCreator: App.shared.accountCreator,
                accountManager: App.shared.accountManager,
                predefinedAccountTypeManager: App.shared.predefinedAccountTypeManager,
                walletManager: App.shared.walletManager,
                derivationSettingsManager: App.shared.derivationSettingsManager,
                bitcoinCashCoinTypeManager: App.shared.bitcoinCashCoinTypeManager
        )
        let viewModel = CreateWalletViewModel(service: service)
        let view = CreateWalletViewController(viewModel: viewModel, onComplete: onComplete)

        switch mode {
        case .push(let navigationController):
            navigationController?.pushViewController(view, animated: true)
        case .present(let viewController):
            viewController?.present(ThemeNavigationController(rootViewController: view), animated: true)
        }
    }

}
