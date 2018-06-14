import Foundation
import ObjectMapper

struct WrapperUnspentOutput {
    let outputs: [UnspentOutput]
}

extension WrapperUnspentOutput: ImmutableMappable {

    init(map: Map) throws {
        outputs = try map.value("unspent_outputs")
    }

}
