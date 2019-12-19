import ObjectMapper

class InsightDashProvider: IBitcoinForksProvider {
    let name = "Insight.dash.org"

    func url(for hash: String) -> String? {
        "https://insight.dash.org/insight/tx/" + hash 
    }

    var reachabilityUrl: String {
        "https://insight.dash.org/insight-api/block/0" 
    }

    func requestObject(for hash: String) -> JsonApiProvider.RequestObject {
        .get(url: "https://insight.dash.org/insight-api/tx/" + hash, params: nil)
    }

    func convert(json: [String: Any]) -> IBitcoinResponse? {
        try? InsightResponse(JSONObject: json)
    }

}

class InsightResponse: IBitcoinResponse, ImmutableMappable {
    var txId: String?
    var blockTime: Int?
    var blockHeight: Int?
    var confirmations: Int?

    var size: Int?
    var fee: Decimal?
    var feePerByte: Decimal?

    var inputs = [(value: Decimal, address: String?)]()
    var outputs = [(value: Decimal, address: String?)]()

    required init(map: Map) throws {
        txId = try? map.value("txid")
        guard txId != nil else {
            throw MapError(key: "txId", currentValue: "nil", reason: "wrong data")
        }
        blockTime = try? map.value("time")
        blockHeight = try? map.value("height")
        confirmations = try? map.value("confirmations")

        if let fee: Double = try? map.value("fees"), let size: Int = try? map.value("size") {
            let feePerByte = Decimal(fee) * btcRate / Decimal(size)
            self.feePerByte = feePerByte
            self.size = size
            self.fee = Decimal(fee)
        }
        if let vInputs: [[String: Any]] = try? map.value("vin") {
            vInputs.forEach { input in
                if let value = input["value"] as? Double {
                    let address = input["addr"] as? String

                    inputs.append((value: Decimal(value), address: address))
                }

            }
        }
        if let vOutputs: [[String: Any]] = try? map.value("vout") {
            vOutputs.forEach { output in
                if let valueString = output["value"] as? String, let value = Decimal(string: valueString) {
                    var address: String? = nil
                    if let scriptPubKey = output["scriptPubKey"] as? [String: Any], let addresses = scriptPubKey["addresses"] as? [String] {
                        address = addresses.first
                    }
                    outputs.append((value: value, address: address))
                }

            }
        }
    }

}
