import UIKit

enum EvmAddressModule {
    static func viewController(accountType: AccountType) -> UIViewController? {
        guard let service = EvmAddressService(accountType: accountType, evmBlockchainManager: Core.shared.evmBlockchainManager) else {
            return nil
        }

        let viewModel = EvmAddressViewModel(service: service)
        return EvmAddressViewController(viewModel: viewModel)
    }
}
