import ObjectMapper

class HorSysBitcoinProvider: IBitcoinForksProvider {
    let name = "HorizontalSystems.xyz"
    private let url: String
    private let apiUrl: String

    func url(for hash: String) -> String { return url + hash }
    func apiUrl(for hash: String) -> String { return apiUrl + hash }

    init(testMode: Bool) {
        url = testMode ? "http://btc-testnet.horizontalsystems.xyz/apg/tx/" : "https://btc.horizontalsystems.xyz/apg/tx/"
        apiUrl = url
    }

    func convert(json: [String: Any]) -> IBitcoinResponse? {
        return try? HorSysBitcoinResponse(JSONObject: json)
    }
}

class HorSysBitcoinCashProvider: IBitcoinForksProvider {
    let name: String = "HorizontalSystems.xyz"
    private let url: String
    private let apiUrl: String

    func url(for hash: String) -> String { return url + hash }
    func apiUrl(for hash: String) -> String { return apiUrl + hash }

    init(testMode: Bool) {
        url = testMode ? "http://bch-testnet.horizontalsystems.xyz/apg/tx/" : "https://bch.horizontalsystems.xyz/apg/tx/"
        apiUrl = url
    }

    func convert(json: [String: Any]) -> IBitcoinResponse? {
        return try? HorSysBitcoinResponse(JSONObject: json)
    }

}

class HorSysEthereumProvider: IEthereumForksProvider {
    let name: String = "HorizontalSystems.xyz"
    private let url: String
    private let apiUrl: String

    func url(for hash: String) -> String { return url + hash }
    func apiUrl(for hash: String) -> String { return apiUrl + hash }

    init(testMode: Bool) {
        url = testMode ? "http://eth-testnet.horizontalsystems.xyz/apg/tx/" : "https://eth.horizontalsystems.xyz/apg/tx/"
        apiUrl = url
    }

    func convert(json: [String: Any]) -> IEthereumResponse? {
        return try? HorSysEthereumResponse(JSONObject: json)
    }

}

class HorSysBitcoinResponse: IBitcoinResponse, ImmutableMappable {
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

class HorSysEthereumResponse: IEthereumResponse, ImmutableMappable {
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
        blockHeight = try? map.value("tx.blockNumber")

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
