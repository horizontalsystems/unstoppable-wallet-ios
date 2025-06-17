import MarketKit
import SwiftUI
import UIKit

enum ReceiveModule {
    static func viewController(account: Account) -> UIViewController {
        let service = ReceiveService(
            account: account,
            walletManager: Core.shared.walletManager,
            marketKit: Core.shared.marketKit,
            restoreSettingsService: RestoreSettingsService(manager: Core.shared.restoreSettingsManager)
        )

        let viewModel = ReceiveViewModel(service: service)

        let coinProvider = CoinProvider(
            marketKit: Core.shared.marketKit,
            walletManager: Core.shared.walletManager,
            accountType: account.type
        )

        let selectCoinService = ReceiveSelectCoinService(provider: coinProvider)
        let selectCoinViewModel = ReceiveSelectCoinViewModel(service: selectCoinService)

        let viewController = ReceiveSelectCoinViewController(viewModel: selectCoinViewModel)

        return ReceiveViewController(rootViewController: viewController, viewModel: viewModel)
    }

    static func selectTokenViewController(fullCoin: FullCoin, accountType: AccountType, onSelect: ((Token) -> Void)?) -> UIViewController {
        let viewModel = ReceiveTokenViewModel(fullCoin: fullCoin, accountType: accountType)

        let viewController = ReceiveSelectorViewController(viewModel: viewModel)
        viewController.onSelect = onSelect

        return viewController
    }

    static func selectDerivationViewController(wallets: [Wallet], onSelect: ((Wallet) -> Void)?) -> UIViewController {
        let viewModel = ReceiveDerivationViewModel(wallets: wallets)

        let viewController = ReceiveSelectorViewController(viewModel: viewModel)
        viewController.onSelect = onSelect

        return viewController
    }

    static func selectBitcoinCashCoinTypeViewController(wallets: [Wallet], onSelect: ((Wallet) -> Void)?) -> UIViewController {
        let viewModel = ReceiveBitcoinCashCoinTypeViewModel(wallets: wallets)

        let viewController = ReceiveSelectorViewController(viewModel: viewModel)
        viewController.onSelect = onSelect

        return viewController
    }
}

struct ReceiveView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    let account: Account

    func makeUIViewController(context _: Context) -> UIViewController {
        ReceiveModule.viewController(account: account)
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
