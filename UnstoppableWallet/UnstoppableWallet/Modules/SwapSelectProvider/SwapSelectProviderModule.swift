import UIKit
import ThemeKit

struct SwapSelectProviderModule {

    static func viewController(dexManager: ISwapDexManager) -> UIViewController {
        let service = SwapSelectProviderService(dexManager: dexManager, evmBlockchainManager: App.shared.evmBlockchainManager)

        let viewModel = SwapSelectProviderViewModel(service: service)

        return SwapSelectProviderViewController(viewModel: viewModel)
    }

}
