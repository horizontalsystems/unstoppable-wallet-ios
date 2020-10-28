import Foundation

import ObjectMapper
import Alamofire

class ZcashProvider: IZcashProvider {
    let name = "Explorer.zcha.in"

    func url(for hash: String) -> String? {
        "https://api.zcha.in/transactions/" + hash
    }

    var reachabilityUrl: String {
        "https://api.zcha.in/v2/mainnet/network"
    }

    func request(session: Session, hash: String) -> DataRequest {
        session.request("https://api.zcha.in/v2/mainnet/transactions/" + hash)
    }

    func convert(json: [String: Any]) -> IZcashResponse? {
        try? ZcashResponse(JSONObject: json)
    }

}

class ZcashResponse: IZcashResponse, ImmutableMappable {
    var txId: String?
    var blockTime: Int?
    var blockHeight: Int?

    var fee: Decimal?
    var value: Decimal?

    var inputs = [(value: Decimal, address: String?)]()
    var outputs = [(value: Decimal, address: String?)]()

    required init(map: Map) throws {
        txId = try? map.value("hash")
        guard txId != nil else {
            throw MapError(key: "txId", currentValue: "nil", reason: "wrong data")
        }
        blockTime = try? map.value("timestamp")
        blockHeight = try? map.value("blockHeight")

        if let fee: Double = try? map.value("fee") {
            self.fee = Decimal(fee)
        }
        if let vInputs: [[String: Any]] = try? map.value("vin") {
            vInputs.forEach { input in
                if let retrievedVOut = input["retrievedVout"] as? [String: Any] {
                    let parsed = parseValueAddresses(vOut: retrievedVOut)

                    inputs.append(contentsOf: parsed)
                }
            }
        }
        if let vOutputs: [[String: Any]] = try? map.value("vout") {
            vOutputs.forEach { output in
                let parsed = parseValueAddresses(vOut: output)

                outputs.append(contentsOf: parsed)
            }
        }
    }

    private func parseValueAddresses(vOut: [String: Any]) -> [(value: Decimal, address: String?)] {
        guard let value = vOut["value"] as? Double else {
            return []
        }

        let valueDecimal = Decimal(value)

        guard let scriptPubKey = vOut["scriptPubKey"] as? [String: Any],
                let addresses = scriptPubKey["addresses"] as? [String] else {
            return [(value: valueDecimal, address: nil)]
        }

        return addresses.map { address in (value: valueDecimal, address: address) }
    }

}
