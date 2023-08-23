import Foundation

struct WalletTokenBalanceModule {

    static func view(element: WalletModule.Element) -> WalletTokenBalanceView? {
        guard let account = App.shared.accountManager.activeAccount else {
            return nil
        }

        let coinPriceService = WalletCoinPriceService(
                currencyKit: App.shared.currencyKit,
                marketKit: App.shared.marketKit
        )

        let elementServiceFactory = WalletElementServiceFactory(
                adapterManager: App.shared.adapterManager,
                walletManager: App.shared.walletManager,
                cexAssetManager: App.shared.cexAssetManager)
        let elementService = elementServiceFactory.elementService(account: account)

        let tokenBalanceService = WalletTokenBalanceService(
                coinPriceService: coinPriceService,
                elementService: elementService,
                appManager: App.shared.appManager,
                account: account,
                element: element
        )

        let factory = WalletTokenBalanceViewItemFactory()
        let tokenBalanceViewModel = WalletTokenBalanceViewModel(service: tokenBalanceService, factory: factory)
        return WalletTokenBalanceView(viewModel: tokenBalanceViewModel)
    }

}

extension WalletTokenBalanceModule {
}