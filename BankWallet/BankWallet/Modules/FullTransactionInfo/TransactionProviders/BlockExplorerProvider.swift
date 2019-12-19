import ObjectMapper

class BlockExplorerBitcoinProvider: IBitcoinForksProvider {
    let name = "BlockExplorer.com"

    func url(for hash: String) -> String? {
        "https://blockexplorer.com/tx/" + hash
    }

    var reachabilityUrl: String {
        "https://blockexplorer.com/api/block/0"
    }

    func requestObject(for hash: String) -> JsonApiProvider.RequestObject {
        .get(url: "https://blockexplorer.com/api/tx/" + hash, params: nil)
    }

    func convert(json: [String: Any]) -> IBitcoinResponse? {
        try? BlockExplorerBitcoinResponse(JSONObject: json)
    }

}

class BlockExplorerBitcoinCashProvider: IBitcoinForksProvider {
    let name = "BlockExplorer.com"

    func url(for hash: String) -> String? {
        "https://bitcoincash.blockexplorer.com/tx/" + hash
    }

    var reachabilityUrl: String {
        "https://bitcoincash.blockexplorer.com/api/block/0"
    }

    func requestObject(for hash: String) -> JsonApiProvider.RequestObject {
        .get(url: "https://bitcoincash.blockexplorer.com/api/tx/" + hash, params: nil)
    }

    func convert(json: [String: Any]) -> IBitcoinResponse? {
        try? BlockExplorerBitcoinResponse(JSONObject: json)
    }

}

class BlockExplorerBitcoinResponse: IBitcoinResponse, ImmutableMappable {
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
        blockTime = try? map.value("blocktime")
        blockHeight = try? map.value("blockheight")
        confirmations = try? map.value("confirmations")

        size = try? map.value("size")
        if let feeDouble: Double = try? map.value("fees") {
            fee = Decimal(feeDouble)
        }

        if let fee = fee, let size = size {
            feePerByte = fee * btcRate / Decimal(size)
        }

        if let vInputs: [[String: Any]] = try? map.value("vin") {
            vInputs.forEach { input in
                if let valueDouble = input["value"] as? Double {
                    let value = Decimal(valueDouble)
                    let address = input["addr"] as? String

                    inputs.append((value: value, address: address))
                }

            }
        }
        if let vOutputs: [[String: Any]] = try? map.value("vout") {
            vOutputs.forEach { output in
                if let valueString = output["value"] as? String, let value = Decimal(string: valueString), let txScriptPubKey = output["scriptPubKey"] as? [String: Any] {
                    let address = (txScriptPubKey["addresses"] as? [String])?.first

                    outputs.append((value: value, address: address))
                }

            }
        }
    }

}
