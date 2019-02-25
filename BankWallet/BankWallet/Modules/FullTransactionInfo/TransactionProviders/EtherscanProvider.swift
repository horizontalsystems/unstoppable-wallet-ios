import ObjectMapper
import BigInt

class EtherscanEthereumProvider: IEthereumForksProvider {
    let name: String = "Etherscan.io"

    func url(for hash: String) -> String { return "https://etherscan.io/tx/" + hash }
    func apiUrl(for hash: String) -> String { return "https://api.etherscan.io/api?module=proxy&action=eth_getTransactionByHash&txhash=" + hash }

    func convert(json: [String: Any]) -> IEthereumResponse? {
        return try? EtherscanEthereumResponse(JSONObject: json)
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

    required init(map: Map) throws {
        txId = try? map.value("result.hash")

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

        if input == "0x", let valueString: String = try? map.value("result.value"), let valueBigInt = BigInt(valueString.replacingOccurrences(of: "0x", with: ""), radix: 16), let value = Decimal(string: valueBigInt.description) {
            self.value = value / ethRate
        } else if let input = input, input.contains("0xa9059cbb") {
            let startIndex = input.index(input.startIndex, offsetBy: 10 + 64)
            let endIndex = input.index(startIndex, offsetBy: 64)
            let amountHexString = String(input[startIndex..<endIndex])
            if let weiAmount = BigInt(amountHexString, radix: 16), let weiAmountDecimal = Decimal(string: "\(weiAmount)") {
                self.value = weiAmountDecimal / ethRate
            }
        }

        from = try? map.value("result.from")
        to = try? map.value("result.to")
    }

}
