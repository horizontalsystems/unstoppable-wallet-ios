import ThemeKit

struct AddBep2TokenModule {

    static func viewController() -> UIViewController {
        let blockchainService = AddBep2TokenBlockchainService(
                appConfigProvider: App.shared.appConfigProvider,
                networkManager: App.shared.networkManager
        )
        let service = AddTokenService(blockchainService: blockchainService, coinManager: App.shared.coinManager, walletManager: App.shared.walletManager, accountManager: App.shared.accountManager)
        let viewModel = AddTokenViewModel(service: service)

        let viewController = AddTokenViewController(
                viewModel: viewModel,
                pageTitle: "add_bep2_token.title".localized,
                referenceTitle: "add_bep2_token.token_symbol".localized
        )

        return ThemeNavigationController(rootViewController: viewController)
    }

}
