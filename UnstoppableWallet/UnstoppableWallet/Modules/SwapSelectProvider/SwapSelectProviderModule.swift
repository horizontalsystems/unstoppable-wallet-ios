import UIKit
import ThemeKit

struct SwapSelectProviderModule {

    static func viewController(dataSourceManager: SwapProviderManager) -> UIViewController {
        let service = SwapSelectProviderService(dataSourceManager: dataSourceManager)

        let viewModel = SwapSelectProviderViewModel(service: service)

        return SwapSelectProviderViewController(viewModel: viewModel)
    }

}
