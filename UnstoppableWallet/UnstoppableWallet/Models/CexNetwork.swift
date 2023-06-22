import MarketKit

struct CexNetwork {
    let network: String
    let name: String
    let isDefault: Bool
    let depositEnabled: Bool
    let withdrawEnabled: Bool
    let blockchain: Blockchain?

    var networkName: String {
        blockchain?.name ?? name
    }

}

extension CexNetwork: Hashable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(network)
    }

    static func ==(lhs: CexNetwork, rhs: CexNetwork) -> Bool {
        lhs.network == rhs.network && lhs.name == rhs.name && lhs.isDefault == rhs.isDefault && lhs.depositEnabled == rhs.depositEnabled && lhs.withdrawEnabled == rhs.withdrawEnabled && lhs.blockchain == rhs.blockchain
    }

}
