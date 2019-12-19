import ObjectMapper

class HorSysBitcoinProvider: IBitcoinForksProvider {
    let name = "HorizontalSystems.xyz"
    private let apiUrl: String
    let reachabilityUrl: String

    func url(for hash: String) -> String? {
        nil
    }

    func requestObject(for hash: String) -> JsonApiProvider.RequestObject {
        .get(url: apiUrl + hash, params: nil)
    }

    init(testMode: Bool) {
        apiUrl = testMode ? "http://btc-testnet.horizontalsystems.xyz/apg/tx/" : "https://btc.horizontalsystems.xyz/apg/tx/"
        reachabilityUrl = testMode ? "http://btc-testnet.horizontalsystems.xyz/apg/block/0" : "https://btc.horizontalsystems.xyz/apg/block/0"
    }

    func convert(json: [String: Any]) -> IBitcoinResponse? {
        try? HorSysBitcoinResponse(JSONObject: json)
    }
}

class HorSysBitcoinCashProvider: IBitcoinForksProvider {
    let name: String = "HorizontalSystems.xyz"
    private let url: String
    private let apiUrl: String
    let reachabilityUrl: String

    func url(for hash: String) -> String? {
        return url + hash
    }

    func requestObject(for hash: String) -> JsonApiProvider.RequestObject {
        return .get(url: apiUrl + hash, params: nil)
    }

    init(testMode: Bool) {
        url = testMode ? "http://bch-testnet.horizontalsystems.xyz/apg/tx/" : "https://bch.horizontalsystems.xyz/apg/tx/"
        apiUrl = url
        reachabilityUrl = testMode ? "http://bch-testnet.horizontalsystems.xyz/apg/block/0" : "https://bch.horizontalsystems.xyz/apg/block/0"
    }

    func convert(json: [String: Any]) -> IBitcoinResponse? {
        return try? HorSysBitcoinResponse(JSONObject: json)
    }

}

class HorSysDashProvider: IBitcoinForksProvider {
    let name = "HorizontalSystems.xyz"
    private let url: String
    private let apiUrl: String
    let reachabilityUrl: String

    func url(for hash: String) -> String? {
        return url + hash
    }

    func requestObject(for hash: String) -> JsonApiProvider.RequestObject {
        return .get(url: apiUrl + hash, params: nil)
    }

    init(testMode: Bool) {
        url = testMode ? "http://dash-testnet.horizontalsystems.xyz/insight/tx/" : "https://dash.horizontalsystems.xyz/insight/tx/"
        apiUrl = testMode ? "http://dash-testnet.horizontalsystems.xyz/apg/tx/" : "https://dash.horizontalsystems.xyz/apg/tx/"
        reachabilityUrl = testMode ? "http://dash-testnet.horizontalsystems.xyz/apg/block/0" : "https://dash.horizontalsystems.xyz/apg/block/0"
    }

    func convert(json: [String: Any]) -> IBitcoinResponse? {
        return try? InsightResponse(JSONObject: json)
    }
}

class HorSysEthereumProvider: IEthereumForksProvider {
    let name: String = "HorizontalSystems.xyz"
    private let url: String
    private let apiUrl: String
    let reachabilityUrl: String

    func url(for hash: String) -> String? {
        url + hash
    }

    func requestObject(for hash: String) -> JsonApiProvider.RequestObject {
        .get(url: apiUrl + hash, params: nil)
    }

    init(testMode: Bool) {
        url = testMode ? "http://eth-ropsten.horizontalsystems.xyz/tx/" : "https://eth.horizontalsystems.xyz/tx/"
        apiUrl = testMode ? "http://eth-ropsten.horizontalsystems.xyz/api?module=transaction&action=gettxinfo&txhash=" : "https://eth.horizontalsystems.xyz/api?module=transaction&action=gettxinfo&txhash="
        reachabilityUrl = testMode ? "http://eth-ropsten.horizontalsystems.xyz/apg/block/0" : "https://eth.horizontalsystems.xyz/apg/block/0"
    }

    func convert(json: [String: Any]) -> IEthereumResponse? {
        try? HorSysEthereumResponse(JSONObject: json)
    }

}

class HorSysBitcoinResponse: IBitcoinResponse, ImmutableMappable {
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
        txId = try? map.value("hash")
        guard txId != nil else {
            throw MapError(key: "txId", currentValue: "nil", reason: "wrong data")
        }
        blockTime = try? map.value("time")
        blockHeight = try? map.value("height")
        confirmations = try? map.value("confirmations")

        if let fee: Double = try? map.value("fee"), let rate: Int = try? map.value("rate") {
            let feePerByte = Decimal(rate) / 1000
            self.feePerByte = feePerByte
            size = NSDecimalNumber(decimal: Decimal(fee) / feePerByte).intValue
            self.fee = Decimal(fee) / btcRate
        }
        if let vInputs: [[String: Any]] = try? map.value("inputs") {
            vInputs.forEach { input in
                if let coin = input["coin"] as? [String: Any], let value = coin["value"] as? Int {
                    let address = coin["address"] as? String

                    inputs.append((value: Decimal(value) / btcRate, address: address))
                }

            }
        }
        if let vOutputs: [[String: Any]] = try? map.value("outputs") {
            vOutputs.forEach { output in
                if let value = output["value"] as? Int {
                    let address = output["address"] as? String

                    outputs.append((value: Decimal(value) / btcRate, address: address))
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

    var gasPrice: Decimal?
    var gasUsed: Decimal?
    var gasLimit: Decimal?
    var fee: Decimal?
    var value: Decimal?

    var nonce: Int?
    var from: String?
    var to: String?
    var contractAddress: String?

    required init(map: Map) throws {
        txId = try? map.value("result.hash")
        guard txId != nil else {
            throw MapError(key: "txId", currentValue: "nil", reason: "wrong data")
        }
        if let blockTimeString: String = try? map.value("result.timeStamp") {
            blockTime = Int(blockTimeString)
        }
        if let blockHeightString: String = try? map.value("result.blockNumber") {
            blockHeight = Int(blockHeightString)
        }
        if let confirmationsString: String = try? map.value("result.confirmations") {
            confirmations = Int(confirmationsString)
        }

        if let gasUsedString: String = try? map.value("result.gasUsed") {
            gasUsed = Decimal(string: gasUsedString)
        }
        if let gasLimitString: String = try? map.value("result.gasLimit") {
            gasLimit = Decimal(string: gasLimitString)
        }

        let input: String? = try? map.value("result.input")
        if input == "0x" {
            if let valueString: String = try? map.value("result.value"), let value = Decimal(string: valueString) {
                self.value = value
            }
            to = try? map.value("result.to")
        } else if let input = input, let inputData = ERC20InputParser.parse(input: input) {
            value = inputData.value
            to = inputData.to
            contractAddress = try? map.value("result.to")
        }

        from = try? map.value("result.from")
    }

}
