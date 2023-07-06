import Foundation
import MarketKit

struct CexWithdrawNetwork {
    let id: String
    let name: String
    let isDefault: Bool
    let enabled: Bool
    let minAmount: Decimal
    let maxAmount: Decimal
    let commission: Decimal
    let blockchain: Blockchain?

    var networkName: String {
        blockchain?.name ?? name
    }

}

extension CexWithdrawNetwork: Hashable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func ==(lhs: CexWithdrawNetwork, rhs: CexWithdrawNetwork) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.isDefault == rhs.isDefault && lhs.enabled == rhs.enabled
                && lhs.minAmount == rhs.minAmount && lhs.maxAmount == rhs.maxAmount && lhs.commission == rhs.commission
                && lhs.blockchain == rhs.blockchain
    }

}
