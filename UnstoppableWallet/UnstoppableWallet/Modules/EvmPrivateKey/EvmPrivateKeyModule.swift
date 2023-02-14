import UIKit
import ThemeKit

struct EvmPrivateKeyModule {

    static func viewController(accountType: AccountType) -> UIViewController? {
        guard let service = EvmPrivateKeyService(accountType: accountType, evmBlockchainManager: App.shared.evmBlockchainManager) else {
            return nil
        }

        let viewModel = EvmPrivateKeyViewModel(service: service)
        return EvmPrivateKeyViewController(viewModel: viewModel)
    }

}
