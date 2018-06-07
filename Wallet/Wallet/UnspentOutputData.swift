import Foundation
import ObjectMapper

struct UnspentOutputData {
    let unspentOutputs: [UnspentOutput]
}

extension UnspentOutputData: ImmutableMappable {

    init(map: Map) throws {
        unspentOutputs = try map.value("unspent_outputs")
    }

}
