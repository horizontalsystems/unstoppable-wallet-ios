import UIKit
import WalletCore

enum PublicAddressModule {
    static func evmViewController(account: Account) -> UIViewController? {
        guard let service = EvmAddressService(account: account) else {
            return nil
        }

        let viewModel = PublicAddressViewModel(service: service)
        return PublicAddressViewController(viewModel: viewModel, accountType: .evm)
    }

    static func tronViewController(account: Account) -> UIViewController? {
        guard let service = TronAddressService(account: account) else {
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
