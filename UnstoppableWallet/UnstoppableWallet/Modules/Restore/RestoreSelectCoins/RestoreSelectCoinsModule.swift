import UIKit

struct RestoreSelectCoinsModule {

    static func viewController(predefinedAccountType: PredefinedAccountType, restoreView: RestoreView) -> UIViewController {
        let service = RestoreSelectCoinsService(predefinedAccountType: predefinedAccountType, coinManager: App.shared.coinManager, derivationSettingsManager: App.shared.derivationSettingsManager)
        let viewModel = RestoreSelectCoinsViewModel(service: service)
        return RestoreSelectCoinsViewController(restoreView: restoreView, viewModel: viewModel)
    }

}
