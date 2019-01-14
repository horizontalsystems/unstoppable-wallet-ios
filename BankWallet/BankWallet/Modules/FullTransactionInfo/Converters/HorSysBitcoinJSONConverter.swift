import ObjectMapper

class HorSysBitcoinJSONConverter: IBitcoinJSONConverter {
    let providerName = "HorizontalSystems.xyz"
    private let url: String
    private let apiUrl: String

    init(url: String, apiUrl: String) {
        self.url = url
        self.apiUrl = apiUrl
    }

    func apiUrl(for hash: String) -> String { return apiUrl + hash }
    func url(for hash: String) -> String { return url + hash }

    func convert(json: [String: Any]) -> IBitcoinTxResponse? {
        return try? HorSysBitcoinTxResponse(JSONObject: json)
    }
}

class HorSysBitcoinTxResponse: IBitcoinTxResponse, ImmutableMappable {
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
        txId = try? map.value("hash")
        blockTime = try? map.value("time")
        blockHeight = try? map.value("height")
        confirmations = try? map.value("confirmations")

        if let fee: Double = try? map.value("fee"), let rate: Int = try? map.value("rate") {
            let feePerByte = Double(rate) / 1000
            self.feePerByte = feePerByte
            size = Int(fee / feePerByte)
            self.fee = fee / btcRate
        }
        if let vInputs: [[String: Any]] = try? map.value("inputs") {
            vInputs.forEach { input in
                if let coin = input["coin"] as? [String: Any], let value = coin["value"] as? Int {
                    let address = coin["address"] as? String

                    inputs.append((value: Double(value) / btcRate, address: address))
                }

            }
        }
        if let vOutputs: [[String: Any]] = try? map.value("outputs") {
            vOutputs.forEach { output in
                if let value = output["value"] as? Int {
                    let address = output["address"] as? String

                    outputs.append((value: Double(value) / btcRate, address: address))
                }

            }
        }
    }

}
