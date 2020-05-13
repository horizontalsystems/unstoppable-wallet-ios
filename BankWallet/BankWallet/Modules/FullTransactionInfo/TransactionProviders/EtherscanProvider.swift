import ObjectMapper
import BigInt
import Alamofire

class EtherscanEthereumProvider: IEthereumForksProvider {
    let name: String = "Etherscan.io"
    private let url: String
    private let apiUrl: String
    let reachabilityUrl: String

    private let apiKey: String

    func url(for hash: String) -> String? {
        url + hash
    }

    func request(session: Session, hash: String) -> DataRequest {
        let parameters: Parameters = [
            "module": "proxy",
            "action": "eth_getTransactionByHash",
            "txhash": hash,
            "apikey": apiKey
        ]

        return session.request(apiUrl, parameters: parameters)
    }

    init(testMode: Bool, apiKey: String) {
        url = testMode ? "https://ropsten.etherscan.io/tx/" : "https://etherscan.io/tx/"
        apiUrl = testMode ? "https://api-ropsten.etherscan.io/api" : "https://api.etherscan.io/api"
        reachabilityUrl = testMode ? "https://api-ropsten.etherscan.io/api?module=stats&action=ethprice" : "https://api.etherscan.io/api?module=stats&action=ethprice"

        self.apiKey = apiKey
    }

    func convert(json: [String: Any]) -> IEthereumResponse? {
        try? EtherscanEthereumResponse(JSONObject: json)
    }

}

class EtherscanEthereumResponse: IEthereumResponse, ImmutableMappable {
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
        let result: [String: Any] = try map.value("result")

        txId = result["hash"] as? String

        if let heightString = result["blockNumber"] as? String {
            blockHeight = Int(heightString.replacingOccurrences(of: "0x", with: ""), radix: 16)
        }

        if let gasString = result["gas"] as? String, let gasInt = Int(gasString.replacingOccurrences(of: "0x", with: ""), radix: 16) {
            gasLimit = Decimal(gasInt)
        }

        if let gasPriceString = result["gasPrice"] as? String, let gasPriceInt = Int(gasPriceString.replacingOccurrences(of: "0x", with: ""), radix: 16) {
            gasPrice = Decimal(gasPriceInt) / gweiRate
        }

        if let nonceString = result["nonce"] as? String {
            nonce = Int(nonceString.replacingOccurrences(of: "0x", with: ""), radix: 16)
        }

        let input = result["input"] as? String
        if input == "0x" {
            if let valueString = result["value"] as? String, let valueBigInt = BigInt(valueString.replacingOccurrences(of: "0x", with: ""), radix: 16), let value = Decimal(string: valueBigInt.description) {
                self.value = value
            }
            to = result["to"] as? String
        } else if let input = input, let inputData = ERC20InputParser.parse(input: input) {
            value = inputData.value
            to = inputData.to
            contractAddress = result["to"] as? String
        }

        from = result["from"] as? String
    }

}
