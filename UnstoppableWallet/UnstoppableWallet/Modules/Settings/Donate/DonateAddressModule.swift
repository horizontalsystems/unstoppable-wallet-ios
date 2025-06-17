import UIKit

enum DonateAddressModule {
    static var viewController: UIViewController {
        let viewModel = DonateAddressViewModel(marketKit: Core.shared.marketKit)
        return DonateAddressViewController(viewModel: viewModel)
    }
}
