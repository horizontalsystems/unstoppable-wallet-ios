import Foundation
import ObjectMapper

struct BlockchainTransaction {
    let hash: String
    let blockHeight: Int
    let time: Int
}

extension BlockchainTransaction: ImmutableMappable {

    init(map: Map) throws {
        hash = try map.value("hash")
        blockHeight = try map.value("block_height")
        time = try map.value("time")
    }

}
