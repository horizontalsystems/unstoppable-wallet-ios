import ThemeKit

struct AddBep2TokenModule {

    static func viewController() -> UIViewController? {
        guard let account = App.shared.accountManager.activeAccount else {
            return nil
        }

        let blockchainService = AddBep2TokenBlockchainService(
                appConfigProvider: App.shared.appConfigProvider,
                networkManager: App.shared.networkManager
        )

        let service = AddTokenService(account: account, blockchainService: blockchainService, coinManager: App.shared.coinManager, walletManager: App.shared.walletManager)
        let viewModel = AddTokenViewModel(service: service)

        let viewController = AddTokenViewController(
                viewModel: viewModel,
                pageTitle: "add_bep2_token.title".localized,
                referenceTitle: "add_bep2_token.token_symbol".localized
        )

        return ThemeNavigationController(rootViewController: viewController)
    }

}
