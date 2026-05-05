import EvmKit
import HsExtensions
import TronKit

protocol IPublicAddressService {
    var address: String { get }
}

class EvmAddressService: IPublicAddressService {
    let address: String

    init?(account: Account) {
        guard let address = try? AccountAddress.evmAddress(account: account, blockchainType: .ethereum)
        else {
            return nil
        }
        self.address = address.eip55
    }
}

class TronAddressService: IPublicAddressService {
    let address: String

    init?(account: Account) {
        guard let address = try? AccountAddress.tronAddress(account: account) else {
            return nil
        }
        self.address = address.base58
    }
}
