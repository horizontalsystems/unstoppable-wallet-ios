import UIKit
import ThemeKit

struct BaseCurrencySettingsModule {

    static func viewController() -> UIViewController {
        let service = BaseCurrencySettingsService(currencyManager: App.shared.currencyManager)
        let viewModel = BaseCurrencySettingsViewModel(service: service)
        return BaseCurrencySettingsViewController(viewModel: viewModel)
    }

}
