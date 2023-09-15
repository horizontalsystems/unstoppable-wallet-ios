import UIKit
import ThemeKit
import MarketKit

struct ReceiveModule {

    static func viewController() -> UIViewController? {
        guard let account = App.shared.accountManager.activeAccount else {
            return nil
        }

        let service = ReceiveService(
                account: account,
                walletManager: App.shared.walletManager,
                marketKit: App.shared.marketKit,
                restoreSettingsService: RestoreSettingsService(manager: App.shared.restoreSettingsManager)
        )

        let viewModel = ReceiveViewModel(service: service)

        let coinProvider = CoinProvider(
                marketKit: App.shared.marketKit,
                walletManager: App.shared.walletManager,
                accountType: account.type
        )

        let selectCoinService = ReceiveSelectCoinService(provider: coinProvider)
        let selectCoinViewModel = ReceiveSelectCoinViewModel(service: selectCoinService)

        let viewController = ReceiveSelectCoinViewController(viewModel: selectCoinViewModel)

        return ReceiveViewController(rootViewController: viewController, viewModel: viewModel)
    }

    static func selectTokenViewController(fullCoin: FullCoin, accountType: AccountType, onSelect: ((Token) -> ())?) -> UIViewController {
        let viewModel = ReceiveTokenViewModel(fullCoin: fullCoin, accountType: accountType)

        let viewController = ReceiveSelectorViewController(viewModel: viewModel)
        viewController.onSelect = onSelect

        return viewController
    }

    static func selectDerivationViewController(wallets: [Wallet], onSelect: ((Wallet) -> ())?) -> UIViewController {
        let viewModel = ReceiveDerivationViewModel(wallets: wallets)

        let viewController = ReceiveSelectorViewController(viewModel: viewModel)
        viewController.onSelect = onSelect

        return viewController
    }

    static func selectBitcoinCashCoinTypeViewController(wallets: [Wallet], onSelect: ((Wallet) -> ())?) -> UIViewController {
        let viewModel = ReceiveBitcoinCashCoinTypeViewModel(wallets: wallets)

        let viewController = ReceiveSelectorViewController(viewModel: viewModel)
        viewController.onSelect = onSelect

        return viewController
    }

}
