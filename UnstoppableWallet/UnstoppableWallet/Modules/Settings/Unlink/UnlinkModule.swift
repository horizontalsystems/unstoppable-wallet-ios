import UIKit

enum UnlinkModule {
    static func viewController(account: Account) -> UIViewController {
        let service = UnlinkService(account: account, accountManager: Core.shared.accountManager)
        let viewModel = UnlinkViewModel(service: service)
        let viewController = account.watchAccount ? UnlinkWatchViewController(viewModel: viewModel) : UnlinkViewController(viewModel: viewModel)
        return viewController.toBottomSheet
    }
}
