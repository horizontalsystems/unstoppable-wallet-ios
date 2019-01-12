import Foundation
import ObjectMapper

class BlockChairBitcoinJSONConverter: IBitcoinJSONConverter {

    func convert(json: [String: Any]) -> IBitcoinTxResponse? {
        return try? BlockChairBitcoinTxResponse(JSONObject: json)
    }
}

class BlockChairBitcoinTxResponse: IBitcoinTxResponse, ImmutableMappable {
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

        if let fee: Double = try? map.value("data.\(key).transaction.fee"), let size: Int = try? map.value("data.\(key).transaction.size") {
            self.fee = fee / btcRate
            self.size = size
            feePerByte = fee / Double(size)
        }
        if let vInputs: [[String: Any]] = try? map.value("data.\(key).inputs") {
            vInputs.forEach { input in
                if let value = input["value"] as? Double {
                    inputs.append((value: value / btcRate, address: input["recipient"] as? String))
                }
            }
        }
        if let vOutputs: [[String: Any]] = try? map.value("data.\(key).outputs") {
            vOutputs.forEach { output in
                if let value = output["value"] as? Double {
                    outputs.append((value: value / btcRate, address: output["recipient"] as? String))
                }
            }
        }
    }

}

