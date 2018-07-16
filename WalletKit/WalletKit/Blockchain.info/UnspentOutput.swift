import Foundation
import ObjectMapper

struct UnspentOutput {
    let value: Int
}

extension UnspentOutput: ImmutableMappable {

    init(map: Map) throws {
        value = try map.value("value")
    }

}
