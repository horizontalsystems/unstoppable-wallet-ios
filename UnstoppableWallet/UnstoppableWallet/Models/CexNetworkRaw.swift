import ObjectMapper
import MarketKit

struct CexNetworkRaw: ImmutableMappable {
    let network: String
    let name: String
    let isDefault: Bool
    let depositEnabled: Bool
    let withdrawEnabled: Bool
    let blockchainUid: String?

    init(network: String, name: String, isDefault: Bool, depositEnabled: Bool, withdrawEnabled: Bool, blockchainUid: String?) {
        self.network = network
        self.name = name
        self.isDefault = isDefault
        self.depositEnabled = depositEnabled
        self.withdrawEnabled = withdrawEnabled
        self.blockchainUid = blockchainUid
    }

    init(map: Map) throws {
        network = try map.value("network")
        name = try map.value("name")
        isDefault = try map.value("isDefault")
        depositEnabled = try map.value("depositEnabled")
        withdrawEnabled = try map.value("withdrawEnabled")
        blockchainUid = try map.value("blockchainUid")
    }

    func mapping(map: Map) {
        network >>> map["network"]
        name >>> map["name"]
        isDefault >>> map["isDefault"]
        depositEnabled >>> map["depositEnabled"]
        withdrawEnabled >>> map["withdrawEnabled"]
        blockchainUid >>> map["blockchainUid"]
    }

    func cexNetwork(blockchain: Blockchain?) -> CexNetwork {
        CexNetwork(
                network: network,
                name: name,
                isDefault: isDefault,
                depositEnabled: depositEnabled,
                withdrawEnabled: withdrawEnabled,
                blockchain: blockchain
        )
    }
}
