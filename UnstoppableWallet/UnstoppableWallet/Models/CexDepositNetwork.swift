import Foundation
import MarketKit

struct CexDepositNetwork {
    let id: String
    let name: String
    let isDefault: Bool
    let enabled: Bool
    let minAmount: Decimal
    let blockchain: Blockchain?

    var networkName: String {
        blockchain?.name ?? name
    }

}

extension CexDepositNetwork: Hashable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func ==(lhs: CexDepositNetwork, rhs: CexDepositNetwork) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.isDefault == rhs.isDefault && lhs.enabled == rhs.enabled && lhs.minAmount == rhs.minAmount && lhs.blockchain == rhs.blockchain
    }

}
