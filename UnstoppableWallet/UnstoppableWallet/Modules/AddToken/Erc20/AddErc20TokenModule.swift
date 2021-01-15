import ThemeKit

struct AddErc20TokenModule {

    static func viewController() -> UIViewController {
        let blockchainService = AddErc20TokenBlockchainService(
                appConfigProvider: App.shared.appConfigProvider,
                networkManager: App.shared.networkManager
        )

        let service = AddTokenService(blockchainService: blockchainService, coinManager: App.shared.coinManager, walletManager: App.shared.walletManager, accountManager: App.shared.accountManager)
        let viewModel = AddTokenViewModel(service: service)

        let viewController = AddTokenViewController(
                viewModel: viewModel,
                pageTitle: "add_erc20_token.title".localized,
                referenceTitle: "add_erc20_token.contract_address".localized
        )

        return ThemeNavigationController(rootViewController: viewController)
    }

}
