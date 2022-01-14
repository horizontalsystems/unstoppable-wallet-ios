import UIKit

struct UnlinkModule {

    static func viewController(account: Account) -> UIViewController {
        let service = UnlinkService(account: account, accountManager: App.shared.accountManager)
        let viewModel = UnlinkViewModel(service: service)
        let viewController = account.watchAccount ? UnlinkWatchViewController(viewModel: viewModel) : UnlinkViewController(viewModel: viewModel)
        return viewController.toBottomSheet
    }

}
