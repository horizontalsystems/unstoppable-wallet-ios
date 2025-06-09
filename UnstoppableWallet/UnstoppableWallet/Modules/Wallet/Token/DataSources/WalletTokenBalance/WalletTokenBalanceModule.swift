import Foundation

enum WalletTokenBalanceModule {
    static func dataSource(wallet: Wallet) -> WalletTokenBalanceDataSource? {
        guard let account = App.shared.accountManager.activeAccount else {
            return nil
        }

        let coinPriceService = WalletCoinPriceService(
            currencyManager: App.shared.currencyManager,
            priceChangeModeManager: App.shared.priceChangeModeManager,
            marketKit: App.shared.marketKit
        )

        let walletServiceFactory = WalletServiceFactory(
            adapterManager: App.shared.adapterManager,
            walletManager: App.shared.walletManager
        )

        let walletService = walletServiceFactory.walletService(account: account)

        let tokenBalanceService = WalletTokenBalanceService(
            coinPriceService: coinPriceService,
            walletService: walletService,
            appManager: App.shared.appManager,
            cloudAccountBackupManager: App.shared.cloudBackupManager,
            balanceHiddenManager: App.shared.balanceHiddenManager,
            reachabilityManager: App.shared.reachabilityManager,
            account: account,
            wallet: wallet
        )

        let factory = WalletTokenBalanceViewItemFactory()
        let tokenBalanceViewModel = WalletTokenBalanceViewModel(service: tokenBalanceService, factory: factory)
        return WalletTokenBalanceDataSource(viewModel: tokenBalanceViewModel)
    }
}
