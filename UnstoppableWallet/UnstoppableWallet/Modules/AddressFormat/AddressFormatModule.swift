import UIKit

struct AddressFormatModule {

    static func viewController() -> UIViewController {
        let service = AddressFormatService(
                derivationSettingsManager: App.shared.derivationSettingsManager,
                bitcoinCashCoinTypeManager: App.shared.bitcoinCashCoinTypeManager
        )

        let viewModel = AddressFormatViewModel(service: service)

        return AddressFormatViewController(viewModel: viewModel)
    }

}
