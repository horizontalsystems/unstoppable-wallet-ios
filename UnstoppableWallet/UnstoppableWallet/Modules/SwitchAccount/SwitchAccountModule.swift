import UIKit

struct SwitchAccountModule {

    static func viewController() -> UIViewController {
        let service = SwitchAccountService(accountManager: App.shared.accountManager)
        let viewModel = SwitchAccountViewModel(service: service)
        return SwitchAccountViewController(viewModel: viewModel).toBottomSheet
    }

}
