import ObjectMapper
import BigInt

class BinanceOrgProvider: IBinanceProvider {
    let name: String = "Binance.org"
    private let url: String
    private let apiUrl: String
    let reachabilityUrl: String

    func url(for hash: String) -> String? {
        url + hash
    }

    func requestObject(for hash: String) -> JsonApiProvider.RequestObject {
        .get(url: apiUrl + hash + "?format=json", params: nil)
    }

    init(testMode: Bool) {
        url = testMode ? "https://testnet-explorer.binance.org/tx/" : "https://explorer.binance.org/tx/"
        apiUrl = testMode ? "https://testnet-dex.binance.org/api/v1/tx/" : "https://dex.binance.org/api/v1/tx/"
        reachabilityUrl = testMode ? "https://testnet-dex.binance.org/api/v1/node-info" : "https://dex.binance.org/api/v1/node-info"
    }

    func convert(json: [String: Any]) -> IBinanceResponse? {
        try? BinanceOrgBinanceResponse(JSONObject: json)
    }

}

class BinanceOrgBinanceResponse: IBinanceResponse, ImmutableMappable {
    var txId: String?
    var blockHeight: Int?

    let fee: Decimal? = BinanceAdapter.transferFee
    var value: Decimal?

    var from: String?
    var to: String?

    var memo: String?

    required init(map: Map) throws {
        txId = try? map.value("hash")

        if let heightString: String = try? map.value("height") {
            blockHeight = Int(heightString, radix: 10)
        }

        guard let msgs: [[String: Any]] = try? map.value("tx.value.msg"), let firstMsg = msgs.first,
              let anyMsgValue = firstMsg["value"], let msgValue = anyMsgValue as? [String: Any] else {
            return
        }

        if let anyInputs = msgValue["inputs"], let inputs = anyInputs as? [[String: Any]], let firstInput = inputs.first,
           let anyFromAddress = firstInput["address"], let fromAddress = anyFromAddress as? String {
            from = fromAddress

            if let anyCoins = firstInput["coins"], let coins = anyCoins as? [[String: Any]], let coin = coins.first,
               let anyAmount = coin["amount"], let amountStr = anyAmount as? String,
               let amount = Decimal(string: amountStr) {
                value = amount
            }
        }

        if let anyOutputs = msgValue["outputs"], let outputs = anyOutputs as? [[String: Any]], let firstOutput = outputs.first,
           let anyToAddress = firstOutput["address"], let toAddress = anyToAddress as? String {
            to = toAddress
        }

        if let memoString: String = try? map.value("tx.value.memo") {
            memo = memoString
        }
    }

}
