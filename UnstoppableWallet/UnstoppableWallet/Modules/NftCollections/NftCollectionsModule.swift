import UIKit
import ThemeKit

struct NftCollectionsModule {

    static func viewController() -> UIViewController {
        let service = NftCollectionsService(
                currencyKit: App.shared.currencyKit
        )

        let viewModel = NftCollectionsViewModel(service: service)
        let headerViewModel = NftCollectionsHeaderViewModel(service: service)

        return NftCollectionsViewController(viewModel: viewModel, headerViewModel: headerViewModel)
    }

}
