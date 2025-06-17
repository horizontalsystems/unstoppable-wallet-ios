import Foundation

enum WalletTokenBalanceModule {
    static func dataSource(wallet: Wallet) -> WalletTokenBalanceDataSource? {
        guard let account = Core.shared.accountManager.activeAccount else {
            return nil
        }

        let coinPriceService = WalletCoinPriceService()
        let walletServiceFactory = WalletServiceFactory()
        let walletService = walletServiceFactory.walletService(account: account)

        let tokenBalanceService = WalletTokenBalanceService(
            coinPriceService: coinPriceService,
            walletService: walletService,
            appManager: Core.shared.appManager,
            cloudAccountBackupManager: Core.shared.cloudBackupManager,
            balanceHiddenManager: Core.shared.balanceHiddenManager,
            reachabilityManager: Core.shared.reachabilityManager,
            account: account,
            wallet: wallet
        )

        let factory = WalletTokenBalanceViewItemFactory()
        let tokenBalanceViewModel = WalletTokenBalanceViewModel(service: tokenBalanceService, factory: factory)
        return WalletTokenBalanceDataSource(viewModel: tokenBalanceViewModel)
    }
}
