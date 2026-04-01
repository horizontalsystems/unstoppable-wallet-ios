import UIKit

enum PublicAddressModule {
    static func evmViewController(accountType: AccountType) -> UIViewController? {
        guard let service = EvmAddressService(accountType: accountType, evmBlockchainManager: Core.shared.evmBlockchainManager) else {
            return nil
        }

        let viewModel = PublicAddressViewModel(service: service)
        return PublicAddressViewController(viewModel: viewModel, accountType: .evm)
    }

    static func tronViewController(accountType: AccountType) -> UIViewController? {
        guard let service = TronAddressService(accountType: accountType) else {
            return nil
        }

        let viewModel = PublicAddressViewModel(service: service)
        return PublicAddressViewController(viewModel: viewModel, accountType: .tron)
    }
}

extension PublicAddressModule {
    enum AbstractAccountType {
        case evm, tron
    }
}
