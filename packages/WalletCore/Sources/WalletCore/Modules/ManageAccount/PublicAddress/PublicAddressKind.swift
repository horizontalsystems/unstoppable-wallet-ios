import EvmKit
import TronKit

enum PublicAddressKind {
    case evm
    case tron

    var title: String {
        switch self {
        case .evm: return "evm_address.title".localized
        case .tron: return "tron_address.title".localized
        }
    }

    // Tron deliberately reuses the EVM stat cases because none exist for Tron
    var statPage: StatPage {
        switch self {
        case .evm, .tron: return .evmAddress
        }
    }

    // Tron deliberately reuses the EVM stat cases because none exist for Tron
    var statEntity: StatEntity {
        switch self {
        case .evm, .tron: return .evmAddress
        }
    }

    func address(account: Account) -> String? {
        switch self {
        case .evm: return (try? AccountAddress.evmAddress(account: account, blockchainType: .ethereum))?.eip55
        case .tron: return (try? AccountAddress.tronAddress(account: account))?.base58
        }
    }
}
