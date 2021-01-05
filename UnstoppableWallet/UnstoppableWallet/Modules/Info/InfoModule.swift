import UIKit

struct InfoModule {

    static func viewController(title: String, dataSource: InfoDataSourceNew) -> UIViewController {
        let viewModel = InfoViewModel(dataSource: dataSource)

        return InfoViewControllerNew(title: title, viewModel: viewModel, urlManager: UrlManager(inApp: true))
    }

}
