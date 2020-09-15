import UIKit

struct RestoreEosModule {

    static func viewController(restoreView: RestoreView) -> UIViewController {
        let service = RestoreEosService(appConfigProvider: App.shared.appConfigProvider)
        let viewModel = RestoreEosViewModel(service: service)
        return RestoreEosViewController(restoreView: restoreView, viewModel: viewModel)
    }

}
