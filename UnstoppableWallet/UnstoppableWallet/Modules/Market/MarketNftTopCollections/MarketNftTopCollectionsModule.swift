import UIKit
import ThemeKit

struct MarketNftTopCollectionsModule {

    static func viewController() -> UIViewController {
        let service = MarketNftTopCollectionsService(provider: App.shared.hsNftProvider, currencyKit: App.shared.currencyKit)

        let decorator = MarketListNftCollectionDecorator(service: service)
        let viewModel = MarketNftTopCollectionsViewModel()
        let listViewModel = MarketListViewModel(service: service, decorator: decorator)
        let headerViewModel = NftCollectionsMultiSortHeaderViewModel(service: service, decorator: decorator)

        let viewController = MarketNftTopCollectionsViewController(viewModel: viewModel, listViewModel: listViewModel, headerViewModel: headerViewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
