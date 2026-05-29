import UIKit

enum TronPrivateKeyModule {
    static func viewController(accountType: AccountType) -> UIViewController? {
        guard let service = TronPrivateKeyService(accountType: accountType) else {
            return nil
        }

        let viewModel = TronPrivateKeyViewModel(service: service)
        return TronPrivateKeyViewController(viewModel: viewModel)
    }
}
