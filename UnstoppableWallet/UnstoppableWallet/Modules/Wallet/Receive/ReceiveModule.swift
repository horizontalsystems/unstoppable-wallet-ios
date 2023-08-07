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
                marketKit: App.shared.marketKit
        )
        let viewModel = ReceiveViewModel(service: service)

        let coinProvider = CoinProvider(
                marketKit: App.shared.marketKit,
                accountType: account.type,
                predefined: service.predefinedCoins
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

    static func proceedTokenDeposit(token: Token) -> UIViewController? {
        let wallets = App.shared.walletManager.activeWallets

        // check if wallet already created or restore new wallet
        switch token.blockchainType {
        case .bitcoin:      // handle bip types
            let bitcoinWallets = wallets.filter { wallet in wallet.token.blockchainType == .bitcoin }

            // if no one wallets exists, restore .bip84 wallet and show address
            if bitcoinWallets.count == 0 {
                let configuredToken = ConfiguredToken(token: token, coinSettings: [.derivation: MnemonicDerivation.bip84.rawValue] )
                let newWallet = Wallet(configuredToken: configuredToken, account: App.shared.accountManager.activeAccount!)
                App.shared.walletManager.save(wallets: [newWallet])

                return DepositModule.viewController(wallet: newWallet)
            }
            // if only one wallet exist just show address. Otherwise show choose derivation type
            if bitcoinWallets.count == 1 {
                return DepositModule.viewController(wallet: bitcoinWallets[0])
            }

            ()
        case .bitcoinCash:  // handle address types
            ()
        case .zcash:        // handle birthday height
            ()
        default:            // just create adapter if needed and make new wallet
            ()
        }

        return UIViewController()
    }

}
