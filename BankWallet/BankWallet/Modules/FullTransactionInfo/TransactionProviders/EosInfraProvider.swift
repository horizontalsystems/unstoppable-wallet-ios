import ObjectMapper

class EosInfraProvider: IEosProvider {

    func convert(json: [String: Any], account: String) -> IEosResponse? {
        try? EosResponse(JSONObject: json, context: EosResponse.AccountContext(account: account))
    }

    var name: String = "Eosnode.tools"

    func url(for hash: String) -> String? {
        nil
//        "https://bloks.io/transaction/\(hash)"
    }

    var reachabilityUrl: String {
        "https://public.eosinfra.io"
    }

    func requestObject(for hash: String) -> JsonApiProvider.RequestObject {
        .post(url: "https://public.eosinfra.io/v1/history/get_transaction", params: ["id": hash])
    }

}

class EosGreymassProvider: IEosProvider {

    func convert(json: [String: Any], account: String) -> IEosResponse? {
        try? EosResponse(JSONObject: json, context: EosResponse.AccountContext(account: account))
    }

    var name: String = "Greymass.com"

    func url(for hash: String) -> String? {
        nil
//        "https://bloks.io/transaction/\(hash)"
    }

    var reachabilityUrl: String {
        "https://eos.greymass.com"
    }

    func requestObject(for hash: String) -> JsonApiProvider.RequestObject {
        .post(url: "https://eos.greymass.com/v1/history/get_transaction", params: ["id": hash])
    }

}

class EosResponse: IEosResponse, ImmutableMappable {
    var txId: String?
    var status: String?
    var cpuUsage: Int?
    var netUsage: Int?
    var blockNumber: Int?
    var blockTime: Date?

    var actions = [EosAction]()

    required init(map: Map) throws {
        txId = try? map.value("id")
        guard txId != nil else {
            throw MapError(key: "txId", currentValue: "nil", reason: "wrong data")
        }
        status = try? map.value("trx.receipt.status")
        cpuUsage = try? map.value("trx.receipt.cpu_usage_us")
        netUsage = try? map.value("trx.receipt.net_usage_words")
        blockNumber = try? map.value("block_num")
        blockTime = try? map.value("block_time", using: TransformOf<Date, String>(fromJSON: { stringDate -> Date? in
            guard let stringDate = stringDate else {
                return nil
            }

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            return formatter.date(from: stringDate)
        }, toJSON: { _ in nil }))

        guard let traces: [[String: Any]] = try? map.value("traces") else {
            return
        }

        guard let accountContext = map.context as? AccountContext else {
            return
        }

        let transferTraces = traces.filter { trace in
            guard let action = trace["act"] as? [String: Any], let receipt = trace["receipt"] as? [String: Any] else {
                return false
            }

            return action["name"] as? String == "transfer" && receipt["receiver"] as? String == accountContext.account
        }

        for trace in transferTraces {
            guard let actionMap = trace["act"] as? [String: Any] else {
                continue
            }

            let contract = actionMap["account"] as? String

            guard let actionData = actionMap["data"] as? [String: Any] else {
                continue
            }
            
            let from = actionData["from"] as? String
            let to = actionData["to"] as? String
            let quantity = actionData["quantity"] as? String
            let memo = actionData["memo"] as? String
            
            let action = EosAction(contract: contract, from: from, to: to, quantity: quantity, memo: memo)
            actions.append(action)
        }
    }

}

extension EosResponse {

    struct AccountContext: MapContext {
        let account: String
    }

}
