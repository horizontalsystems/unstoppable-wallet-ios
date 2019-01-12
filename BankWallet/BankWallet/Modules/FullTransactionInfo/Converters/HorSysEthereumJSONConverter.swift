import Foundation
import ObjectMapper
import BigInt

class HorSysEthereumJSONConverter: IEthereumJSONConverter {
    var resource: String
    let apiUrl: String
    let url: String

    init(resource: String, apiUrl: String, url: String) {
        self.resource = resource
        self.apiUrl = apiUrl
        self.url = url
    }

    func convert(json: [String: Any]) -> IEthereumTxResponse? {
        return try? HorSysEthereumTxResponse(JSONObject: json)
    }
}

class HorSysEthereumTxResponse: IEthereumTxResponse, ImmutableMappable {
    var txId: String?
    var blockTime: Int?
    var blockHeight: Int?
    var confirmations: Int?

    var size: Int?

    var gasPrice: Double?
    var gasUsed: Double?
    var gasLimit: Double?
    var fee: Double?
    var value: Double?

    var nonce: Int?
    var from: String?
    var to: String?

    required init(map: Map) throws {
        txId = try? map.value("tx.hash")
//        blockTime = try? map.value("data.block_time")
        blockHeight = try? map.value("tx.blockNumber")
//        confirmations = try? map.value("data.confirmations")

        gasLimit = try? map.value("tx.gas")
        if let price: String = try? map.value("tx.gasPrice"), let priceDouble = Double(price) {
            gasPrice = priceDouble / gweiRate
        }
        gasUsed = try? map.value("tx.gasUsed")

        if let value: String = try? map.value("tx.value") {
            self.value = NSDecimalNumber(string: value).doubleValue / ethRate
        }

        nonce = try? map.value("tx.nonce")
        to = try? map.value("tx.to")
        from = try? map.value("tx.from")
    }

}
