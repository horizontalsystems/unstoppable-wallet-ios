import Foundation
import ObjectMapper

class EvmUpdateStatus: ImmutableMappable {
    let methodLabels: Int
    let addressLabels: Int

    required init(map: Map) throws {
        methodLabels = try map.value("evm_method_labels")
        addressLabels = try map.value("address_labels")
    }

}
