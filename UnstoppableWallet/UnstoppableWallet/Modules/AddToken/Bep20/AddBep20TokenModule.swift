import ThemeKit

struct AddBep20TokenModule {

    static func viewController() -> UIViewController? {
        guard let account = App.shared.accountManager.activeAccount else {
            return nil
        }

        let blockchainService = AddEvmTokenBlockchainService(
                networkType: App.shared.accountSettingManager.binanceSmartChainNetwork(account: account).networkType,
                appConfigProvider: App.shared.appConfigProvider,
                networkManager: App.shared.networkManager
        )
        let service = AddTokenService(account: account, blockchainService: blockchainService, coinManager: App.shared.coinManager, walletManager: App.shared.walletManager)
        let viewModel = AddTokenViewModel(service: service)

        let viewController = AddTokenViewController(
                viewModel: viewModel,
                pageTitle: "add_bep20_token.title".localized,
                referenceTitle: "add_evm_token.contract_address".localized
        )

        return ThemeNavigationController(rootViewController: viewController)
    }

}
