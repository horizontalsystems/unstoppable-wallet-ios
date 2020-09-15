import UIKit

class RestoreSelectPredefinedAccountTypeModule {

    static func viewController(restoreView: RestoreView) -> UIViewController {
        let service = RestoreSelectPredefinedAccountTypeService(predefinedAccountTypeManager: App.shared.predefinedAccountTypeManager)
        let viewModel = RestoreSelectPredefinedAccountTypeViewModel(service: service)
        return RestoreSelectPredefinedAccountTypeViewController(restoreView: restoreView, viewModel: viewModel)
    }

}
