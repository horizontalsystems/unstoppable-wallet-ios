import UIKit

struct InfoModule {

    static func viewController(dataSource: InfoDataSource) -> UIViewController {
        let viewModel = InfoViewModel(dataSource: dataSource)

        return InfoViewController(viewModel: viewModel, urlManager: UrlManager(inApp: true))
    }

}
