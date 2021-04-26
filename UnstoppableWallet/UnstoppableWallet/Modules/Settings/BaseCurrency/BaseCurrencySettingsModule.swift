import UIKit
import ThemeKit

struct BaseCurrencySettingsModule {

    static func viewController() -> UIViewController {
        let service = BaseCurrencySettingsService(currencyKit: App.shared.currencyKit)
        let viewModel = BaseCurrencySettingsViewModel(service: service)
        return BaseCurrencySettingsViewController(viewModel: viewModel)
    }

}
