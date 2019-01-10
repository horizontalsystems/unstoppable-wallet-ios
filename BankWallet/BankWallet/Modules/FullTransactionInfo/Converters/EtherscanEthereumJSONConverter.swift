import Foundation
import ObjectMapper
import BigInt

class EtherscanEthereumJSONConverter: IEthereumJSONConverter {
    var resource: String
    let apiUrl: String
    let url: String

    init(resource: String, apiUrl: String, url: String) {
        self.resource = resource
        self.apiUrl = apiUrl
        self.url = url
    }

    func convert(json: [String: Any]) -> IEthereumTxResponse? {
        return try? EtherscanEthereumTxResponse(JSONObject: json)
    }
}

class EtherscanEthereumTxResponse: IEthereumTxResponse, ImmutableMappable {
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
        txId = try? map.value("result.hash")

        if let heightString: String = try? map.value("result.blockNumber") {
            blockHeight = Int(heightString.replacingOccurrences(of: "0x", with: ""), radix: 16)
        }

        if let gasString: String = try? map.value("result.gas"), let gasInt = Int(gasString.replacingOccurrences(of: "0x", with: ""), radix: 16) {
            gasLimit = Double(gasInt)
        }

        if let gasPriceString: String = try? map.value("result.gasPrice"), let gasPriceInt = Int(gasPriceString.replacingOccurrences(of: "0x", with: ""), radix: 16) {
            gasPrice = Double(gasPriceInt) / gweiRate
        }

        if let nonceString: String = try? map.value("result.nonce") {
            nonce = Int(nonceString.replacingOccurrences(of: "0x", with: ""), radix: 16)
        }

        if let valueString: String = try? map.value("result.value"), let valueBigInt = BigInt(valueString.replacingOccurrences(of: "0x", with: ""), radix: 16) {
            self.value = NSDecimalNumber(string: valueBigInt.description).doubleValue / ethRate
        }

        from = try? map.value("result.from")
        to = try? map.value("result.to")
    }

}
