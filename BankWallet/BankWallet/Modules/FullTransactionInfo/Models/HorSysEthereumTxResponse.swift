import Foundation
import ObjectMapper

class HorSysEthereumTxResponse: IEthereumTxResponse, ImmutableMappable {
    var txId: String?
    var blockTime: Int?
    var blockHeight: Int?
    var confirmations: Int?

    var size: Int?

    var gasPrice: Double?
    var gasUsed: Double?
    var gasLimit: Double?
    var value: Double?

    var nonce: Int?
    var from: String?
    var to: String?

    required init(map: Map) throws {
        txId = try? map.value("tx.hash")
//        blockTime = try? map.value("data.block_time")
        blockHeight = try? map.value("tx.blockNumber")
//        confirmations = try? map.value("data.confirmations")

        gasLimit = try? map.value("tx.gas")
        if let price: String = try? map.value("tx.gasPrice"), let priceDouble = Double(price) {
            gasPrice = priceDouble / gweiRate
        }
        gasUsed = try? map.value("tx.gasUsed")

        if let value: String = try? map.value("tx.value") {
            self.value = Double(value)
        }

        nonce = try? map.value("tx.nonce")
        to = try? map.value("tx.to")
        from = try? map.value("tx.from")


//        if let fee: Double = try? map.value("data.fee"), let size: Int = try? map.value("data.size") {
//            self.fee = fee / btcRate
//            self.size = size
//            feePerByte = fee / Double(size)
//        }
//        if let vInputs: [[String: Any]] = try? map.value("data.inputs") {
//            vInputs.forEach { input in
//                if let value = input["prev_value"] as? Double {
//                    let address = (input["prev_addresses"] as? [String])?.first
//
//                    inputs.append((value: value / btcRate, address: address))
//                }
//            }
//        }
//        if let vOutputs: [[String: Any]] = try? map.value("data.outputs") {
//            vOutputs.forEach { output in
//                if let value = output["value"] as? Double {
//                    let address = (output["addresses"] as? [String])?.first
//
//                    outputs.append((value: value / btcRate, address: address))
//                }
//            }
//        }
    }

}
