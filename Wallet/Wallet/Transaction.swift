import Foundation
import ObjectMapper

struct PreviousOutput {
    let address: String
}

extension PreviousOutput: ImmutableMappable {
    init(map: Map) throws {
        address = try map.value("addr")
    }
}


struct TransactionInputData {
    let previousOutput: PreviousOutput
}

extension TransactionInputData: ImmutableMappable {
    init(map: Map) throws {
        previousOutput = try map.value("prev_out")
    }
}


struct TransactionOutputData {
    let address: String
    let value: Int64
}

extension TransactionOutputData: ImmutableMappable {
    init(map: Map) throws {
        address = try map.value("addr")
        value   = try map.value("value")
    }
}


struct TransactionData {
    let hash: String
    let inputs: [TransactionInputData]
    let outputs: [TransactionOutputData]
    let result: Int64
    let fee: Int64
    let time: Int64
    let blockHeight: Int64
}

extension TransactionData: ImmutableMappable {
    init(map: Map) throws {
        hash        = try map.value("hash")
        inputs      = try map.value("inputs")
        outputs     = try map.value("out")
        result      = try map.value("result")
        fee         = try map.value("fee")
        time        = try map.value("time")
        blockHeight = try map.value("block_height")
    }
}


struct AddressesData {
    let transactions: [TransactionData]
}

extension AddressesData: ImmutableMappable {
    init(map: Map) throws {
        transactions = try map.value("txs")
    }
}
