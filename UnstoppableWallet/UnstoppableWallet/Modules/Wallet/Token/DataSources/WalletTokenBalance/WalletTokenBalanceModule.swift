import Foundation

struct WalletTokenBalanceModule {

    static func dataSource(element: WalletModule.Element) -> WalletTokenBalanceDataSource? {
        guard let account = App.shared.accountManager.activeAccount else {
            return nil
        }

        let coinPriceService = WalletCoinPriceService(
                tag: "wallet-token-balance",
                currencyKit: App.shared.currencyKit,
                marketKit: App.shared.marketKit
        )

        let elementServiceFactory = WalletElementServiceFactory(
                adapterManager: App.shared.adapterManager,
                walletManager: App.shared.walletManager,
                cexAssetManager: App.shared.cexAssetManager
        )

        let elementService = elementServiceFactory.elementService(account: account)

        let tokenBalanceService = WalletTokenBalanceService(
                coinPriceService: coinPriceService,
                elementService: elementService,
                appManager: App.shared.appManager,
                cloudAccountBackupManager: App.shared.cloudBackupManager,
                balanceHiddenManager: App.shared.balanceHiddenManager,
                reachabilityManager: App.shared.reachabilityManager,
                account: account,
                element: element
        )

        let factory = WalletTokenBalanceViewItemFactory()
        let tokenBalanceViewModel = WalletTokenBalanceViewModel(service: tokenBalanceService, factory: factory)
        return WalletTokenBalanceDataSource(viewModel: tokenBalanceViewModel)
    }

}
