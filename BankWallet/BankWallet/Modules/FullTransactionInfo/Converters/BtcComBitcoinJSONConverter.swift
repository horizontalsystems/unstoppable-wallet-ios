import Foundation
import ObjectMapper

class BtcComBitcoinJSONConverter: IBitcoinJSONConverter {
    var resource: String
    let apiUrl: String
    let url: String

    init(resource: String, apiUrl: String, url: String) {
        self.resource = resource
        self.apiUrl = apiUrl
        self.url = url
    }

    func convert(json: [String: Any]) -> IBitcoinTxResponse? {
        return try? BtcComBitcoinTxResponse(JSONObject: json)
    }
}

class BtcComBitcoinTxResponse: IBitcoinTxResponse, ImmutableMappable {
    var txId: String?
    var blockTime: Int?
    var blockHeight: Int?
    var confirmations: Int?

    var size: Int?
    var fee: Double?
    var feePerByte: Double?

    var inputs = [(value: Double, address: String?)]()
    var outputs = [(value: Double, address: String?)]()

    required init(map: Map) throws {
        txId = try? map.value("data.hash")
        blockTime = try? map.value("data.block_time")
        blockHeight = try? map.value("data.block_height")
        confirmations = try? map.value("data.confirmations")

        if let fee: Double = try? map.value("data.fee"), let size: Int = try? map.value("data.size") {
            self.fee = fee / btcRate
            self.size = size
            feePerByte = fee / Double(size)
        }
        if let vInputs: [[String: Any]] = try? map.value("data.inputs") {
            vInputs.forEach { input in
                if let value = input["prev_value"] as? Double {
                    let address = (input["prev_addresses"] as? [String])?.first

                    inputs.append((value: value / btcRate, address: address))
                }
            }
        }
        if let vOutputs: [[String: Any]] = try? map.value("data.outputs") {
            vOutputs.forEach { output in
                if let value = output["value"] as? Double {
                    let address = (output["addresses"] as? [String])?.first

                    outputs.append((value: value / btcRate, address: address))
                }
            }
        }
    }

}
