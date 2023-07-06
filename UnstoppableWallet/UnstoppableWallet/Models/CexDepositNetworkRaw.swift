import Foundation
import ObjectMapper
import MarketKit

struct CexDepositNetworkRaw: ImmutableMappable {
    let id: String
    let name: String
    let isDefault: Bool
    let enabled: Bool
    let minAmount: Decimal
    let blockchainUid: String?

    init(id: String, name: String, isDefault: Bool, enabled: Bool, minAmount: Decimal, blockchainUid: String?) {
        self.id = id
        self.name = name
        self.isDefault = isDefault
        self.enabled = enabled
        self.minAmount = minAmount
        self.blockchainUid = blockchainUid
    }

    init(map: Map) throws {
        id = try map.value("id")
        name = try map.value("name")
        isDefault = try map.value("isDefault")
        enabled = try map.value("enabled")
        minAmount = try map.value("minAmount", using: Transform.stringToDecimalTransform)
        blockchainUid = try map.value("blockchainUid")
    }

    func mapping(map: Map) {
        id >>> map["id"]
        name >>> map["name"]
        isDefault >>> map["isDefault"]
        enabled >>> map["enabled"]
        minAmount.description >>> map["minAmount"]
        blockchainUid >>> map["blockchainUid"]
    }

    func cexDepositNetwork(blockchain: Blockchain?) -> CexDepositNetwork {
        CexDepositNetwork(
                id: id,
                name: name,
                isDefault: isDefault,
                enabled: enabled,
                minAmount: minAmount,
                blockchain: blockchain
        )
    }

}
