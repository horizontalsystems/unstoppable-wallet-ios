import Foundation
import ObjectMapper
import MarketKit

struct CexWithdrawNetworkRaw: ImmutableMappable {
    let id: String
    let name: String
    let isDefault: Bool
    let enabled: Bool
    let minAmount: Decimal
    let maxAmount: Decimal
    let fixedFee: Decimal
    let feePercent: Decimal
    let minFee: Decimal
    let blockchainUid: String?

    init(id: String, name: String, isDefault: Bool, enabled: Bool, minAmount: Decimal, maxAmount: Decimal, fixedFee: Decimal, feePercent: Decimal, minFee: Decimal, blockchainUid: String?) {
        self.id = id
        self.name = name
        self.isDefault = isDefault
        self.enabled = enabled
        self.minAmount = minAmount
        self.maxAmount = maxAmount
        self.fixedFee = fixedFee
        self.feePercent = feePercent
        self.minFee = minFee
        self.blockchainUid = blockchainUid
    }

    init(map: Map) throws {
        id = try map.value("network")
        name = try map.value("name")
        isDefault = try map.value("isDefault")
        enabled = try map.value("enabled")
        minAmount = try map.value("minAmount", using: Transform.stringToDecimalTransform)
        maxAmount = try map.value("maxAmount", using: Transform.stringToDecimalTransform)
        fixedFee = try map.value("fixedFee", using: Transform.stringToDecimalTransform)
        feePercent = try map.value("feePercent", using: Transform.stringToDecimalTransform)
        minFee = try map.value("minFee", using: Transform.stringToDecimalTransform)
        blockchainUid = try map.value("blockchainUid")
    }

    func mapping(map: Map) {
        id >>> map["network"]
        name >>> map["name"]
        isDefault >>> map["isDefault"]
        enabled >>> map["enabled"]
        minAmount.description >>> map["minAmount"]
        maxAmount.description >>> map["maxAmount"]
        fixedFee.description >>> map["fixedFee"]
        feePercent.description >>> map["feePercent"]
        minFee.description >>> map["minFee"]
        blockchainUid >>> map["blockchainUid"]
    }

    func cexWithdrawNetwork(blockchain: Blockchain?) -> CexWithdrawNetwork {
        CexWithdrawNetwork(
                id: id,
                name: name,
                isDefault: isDefault,
                enabled: enabled,
                minAmount: minAmount,
                maxAmount: maxAmount,
                fixedFee: fixedFee,
                feePercent: feePercent,
                minFee: minFee,
                blockchain: blockchain
        )
    }
}
