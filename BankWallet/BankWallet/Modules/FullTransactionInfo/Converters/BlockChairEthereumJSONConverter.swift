import Foundation
import ObjectMapper
import BigInt

class BlockChairEthereumJSONConverter: IEthereumJSONConverter {
    var resource: String
    let apiUrl: String
    let url: String

    init(resource: String, apiUrl: String, url: String) {
        self.resource = resource
        self.apiUrl = apiUrl
        self.url = url
    }

    func convert(json: [String: Any]) -> IEthereumTxResponse? {
        return try? BlockChairEthereumTxResponse(JSONObject: json)
    }
}

class BlockChairEthereumTxResponse: IEthereumTxResponse, ImmutableMappable {
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
        guard let data: [String: Any] = try? map.value("data"), let key = data.keys.first else {
            return
        }
        txId = try? map.value("data.\(key).transaction.hash")


        if let dateString: String = try? map.value("data.\(key).transaction.time") {

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            formatter.timeZone = TimeZone(identifier: "UTC")
            if let date = formatter.date(from: dateString) {
                blockTime = Int(date.timeIntervalSince1970)
            }
        }
        blockHeight = try? map.value("data.\(key).transaction.block_id")

        gasLimit = try? map.value("data.\(key).transaction.gas_limit")
        if let gasPrice: Double = try? map.value("data.\(key).transaction.gas_price") {
            self.gasPrice = gasPrice / gweiRate
        }
        gasUsed = try? map.value("data.\(key).transaction.gas_used")
        if let feeString: String = try? map.value("data.\(key).transaction.fee"), let feeBigInt = BigInt(feeString) {
            fee = NSDecimalNumber(string: feeBigInt.description).doubleValue / ethRate
        }

        if let nonceString: String = try? map.value("data.\(key).transaction.nonce") {
            nonce = Int(nonceString)
        }

        if let valueString: String = try? map.value("data.\(key).transaction.value"), let valueBigInt = BigInt(valueString) {
            value = NSDecimalNumber(string: valueBigInt.description).doubleValue / ethRate
        }

        from = try? map.value("data.\(key).transaction.sender")
        to = try? map.value("data.\(key).transaction.recipient")
    }

}
