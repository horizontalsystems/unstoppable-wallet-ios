import Foundation
import ObjectMapper

struct UnspentOutput {
    let value: Int64
    let index: Int
    let confirmations: Int64
    let transactionHash: String
    let script: String
}

extension UnspentOutput: ImmutableMappable {

    init(map: Map) throws {
        value           = try map.value("value")
        confirmations   = try map.value("confirmations")
        index           = try map.value("tx_output_n")
        transactionHash = try map.value("tx_hash")
        script          = try map.value("script")
    }

}
