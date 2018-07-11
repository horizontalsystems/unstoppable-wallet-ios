import Foundation
import ObjectMapper

struct UnspentOutputsWrapper {
    let unspentOutputs: [UnspentOutput]
}

extension UnspentOutputsWrapper: ImmutableMappable {

    init(map: Map) throws {
        unspentOutputs = try map.value("unspent_outputs")
    }

}
