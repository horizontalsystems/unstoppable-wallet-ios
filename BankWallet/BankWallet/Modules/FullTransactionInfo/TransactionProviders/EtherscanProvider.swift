import ObjectMapper
import BigInt

class EtherscanEthereumProvider: IEthereumForksProvider {
    let name: String = "Etherscan.io"
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
        url = testMode ? "https://ropsten.etherscan.io/tx/" : "https://etherscan.io/tx/"
        apiUrl = testMode ? "https://api-ropsten.etherscan.io/api?module=proxy&action=eth_getTransactionByHash&txhash=" : "https://api.etherscan.io/api?module=proxy&action=eth_getTransactionByHash&txhash="
        reachabilityUrl = testMode ? "https://api-ropsten.etherscan.io/api?module=stats&action=ethprice" : "https://api.etherscan.io/api?module=stats&action=ethprice"
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
        txId = try? map.value("result.hash")
        guard txId != nil else {
            throw MapError(key: "txId", currentValue: "nil", reason: "wrong data")
        }
        if let heightString: String = try? map.value("result.blockNumber") {
            blockHeight = Int(heightString.replacingOccurrences(of: "0x", with: ""), radix: 16)
        }

        if let gasString: String = try? map.value("result.gas"), let gasInt = Int(gasString.replacingOccurrences(of: "0x", with: ""), radix: 16) {
            gasLimit = Decimal(gasInt)
        }

        if let gasPriceString: String = try? map.value("result.gasPrice"), let gasPriceInt = Int(gasPriceString.replacingOccurrences(of: "0x", with: ""), radix: 16) {
            gasPrice = Decimal(gasPriceInt) / gweiRate
        }

        if let nonceString: String = try? map.value("result.nonce") {
            nonce = Int(nonceString.replacingOccurrences(of: "0x", with: ""), radix: 16)
        }

        let input: String? = try? map.value("result.input")
        if input == "0x" {
            if let valueString: String = try? map.value("result.value"), let valueBigInt = BigInt(valueString.replacingOccurrences(of: "0x", with: ""), radix: 16), let value = Decimal(string: valueBigInt.description) {
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
