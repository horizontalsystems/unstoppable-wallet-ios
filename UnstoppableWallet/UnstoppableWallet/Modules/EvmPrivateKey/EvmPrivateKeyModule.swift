import UIKit
import ThemeKit

struct EvmPrivateKeyModule {

    static func viewController(account: Account) -> UIViewController? {
        guard let service = EvmPrivateKeyService(account: account, evmBlockchainManager: App.shared.evmBlockchainManager) else {
            return nil
        }

        let viewModel = EvmPrivateKeyViewModel(service: service)
        return EvmPrivateKeyViewController(viewModel: viewModel)
    }

}
