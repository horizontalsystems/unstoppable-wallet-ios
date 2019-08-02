import ObjectMapper

class EosInfraProvider: IEosProvider {
    func convert(json: [String: Any]) -> IEosResponse? {
        return try? EosResponse(JSONObject: json)
    }

    var name: String = "eosinfra"

    func url(for hash: String) -> String {
        return "https://bloks.io/transaction/\(hash)"
    }

    func reachabilityUrl(for hash: String) -> String {
        return "https://public.eosinfra.io"
    }

    func requestObject(for hash: String) -> JsonApiProvider.RequestObject {
        return .post(url: "https://public.eosinfra.io/v1/history/get_transaction", params: ["id": hash])
    }

}

class EosResponse: IEosResponse, ImmutableMappable {
    var txId: String?
    var status: String?
    var cpuUsage: Int?
    var netUsage: Int?
    var blockNumber: Int?
    var blockTime: Date?

    var contract: String?
    var from: String?
    var to: String?
    var quantity: String?
    var memo: String?

    required init(map: Map) throws {
        txId = try? map.value("id")
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

        if let traces: [[String: Any]] = try? map.value("traces") {
            let action = (traces.first { dictionary in
                (dictionary["act"] as? [String: Any])?["name"] as? String == "transfer"
            })?["act"] as? [String: Any]
            contract = action?["account"] as? String
            from = (action?["data"] as? [String: Any])?["from"] as? String
            to = (action?["data"] as? [String: Any])?["to"] as? String
            quantity = (action?["data"] as? [String: Any])?["quantity"] as? String
            memo = (action?["data"] as? [String: Any])?["memo"] as? String
        }
    }

}
