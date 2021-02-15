import ThemeKit

struct AddBep20TokenModule {

    static func viewController() -> UIViewController {
        let blockchainService = AddEvmTokenBlockchainService(
                resolver: AddBep20TokenResolver(appConfigProvider: App.shared.appConfigProvider),
                networkManager: App.shared.networkManager
        )

        let service = AddTokenService(blockchainService: blockchainService, coinManager: App.shared.coinManager, walletManager: App.shared.walletManager, accountManager: App.shared.accountManager)
        let viewModel = AddTokenViewModel(service: service)

        let viewController = AddTokenViewController(
                viewModel: viewModel,
                pageTitle: "add_bep20_token.title".localized,
                referenceTitle: "add_evm_token.contract_address".localized
        )

        return ThemeNavigationController(rootViewController: viewController)
    }

}
