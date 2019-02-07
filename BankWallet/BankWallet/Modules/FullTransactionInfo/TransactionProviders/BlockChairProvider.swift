import ObjectMapper
import BigInt

class BlockChairBitcoinProvider: IBitcoinForksProvider {
    let name = "BlockChair.com"

    func url(for hash: String) -> String { return "https://blockchair.com/bitcoin/transaction/" + hash }
    func apiUrl(for hash: String) -> String { return "https://api.blockchair.com/bitcoin/dashboards/transaction/" + hash }

    func convert(json: [String: Any]) -> IBitcoinResponse? {
        return try? BlockChairBitcoinResponse(JSONObject: json)
    }

}

class BlockChairBitcoinCashProvider: IBitcoinForksProvider {
    let name = "BlockChair.com"

    func url(for hash: String) -> String { return "https://blockchair.com/bitcoin-cash/transaction/" + hash }
    func apiUrl(for hash: String) -> String { return "https://api.blockchair.com/bitcoin-cash/dashboards/transaction/" + hash }

    func convert(json: [String: Any]) -> IBitcoinResponse? {
        return try? BlockChairBitcoinResponse(JSONObject: json)
    }

}

class BlockChairEthereumProvider: IEthereumForksProvider {
    let name = "BlockChair.com"

    func url(for hash: String) -> String { return "https://blockchair.com/ethereum/transaction/" + hash }
    func apiUrl(for hash: String) -> String { return "https://api.blockchair.com/ethereum/dashboards/transaction/" + hash }

    func convert(json: [String: Any]) -> IEthereumResponse? {
        return try? BlockChairEthereumResponse(JSONObject: json)
    }

}

class BlockChairBitcoinResponse: IBitcoinResponse, ImmutableMappable {
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
        guard let data: [String: Any] = try? map.value("data"), let key = data.keys.first else {
            return
        }
        txId = try? map.value("data.\(key).transaction.hash")


        if let dateString: String = try? map.value("data.\(key).transaction.time") {

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            formatter.timeZone = TimeZone(identifier: "UTC")
            if let date = formatter.date(from: dateString) {
                blockTime = Int(date.timeIntervalSince1970)
            }
        }
        blockHeight = try? map.value("data.\(key).transaction.block_id")

        if let fee: Int = try? map.value("data.\(key).transaction.fee"), let size: Int = try? map.value("data.\(key).transaction.size") {
            self.fee = Decimal(fee) / btcRate
            self.size = size
            feePerByte = Decimal(fee) / Decimal(size)
        }
        if let vInputs: [[String: Any]] = try? map.value("data.\(key).inputs") {
            vInputs.forEach { input in
                if let value = input["value"] as? Double {
                    inputs.append((value: Decimal(value) / btcRate, address: input["recipient"] as? String))
                }
            }
        }
        if let vOutputs: [[String: Any]] = try? map.value("data.\(key).outputs") {
            vOutputs.forEach { output in
                if let value = output["value"] as? Double {
                    outputs.append((value: Decimal(value) / btcRate, address: output["recipient"] as? String))
                }
            }
        }
    }

}

class BlockChairEthereumResponse: IEthereumResponse, ImmutableMappable {
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
        guard let data: [String: Any] = try? map.value("data"), let key = data.keys.first else {
            return
        }
        txId = try? map.value("data.\(key).transaction.hash")


        if let dateString: String = try? map.value("data.\(key).transaction.time") {

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            formatter.timeZone = TimeZone(identifier: "UTC")
            if let date = formatter.date(from: dateString) {
                blockTime = Int(date.timeIntervalSince1970)
            }
        }
        blockHeight = try? map.value("data.\(key).transaction.block_id")

        gasLimit = try? map.value("data.\(key).transaction.gas_limit")
        if let gasPriceDouble: Double = try? map.value("data.\(key).transaction.gas_price") {
            self.gasPrice = Decimal(gasPriceDouble) / gweiRate
        }
        gasUsed = try? map.value("data.\(key).transaction.gas_used")
        if let feeString: String = try? map.value("data.\(key).transaction.fee"), let value = Decimal(string: feeString) {
            fee = value / ethRate
        }

        if let nonceString: String = try? map.value("data.\(key).transaction.nonce") {
            nonce = Int(nonceString)
        }

        if let valueString: String = try? map.value("data.\(key).transaction.value"), let value = Decimal(string: valueString) {
            self.value = value / ethRate
        }

        from = try? map.value("data.\(key).transaction.sender")
        to = try? map.value("data.\(key).transaction.recipient")
    }

}
