import ZcashLightClientKit

extension SingleUseTransparentAddress {
    var addressString: String? {
        let mirror = Mirror(reflecting: self)
        return mirror.children.first(where: { $0.label == "address" })?.value as? String
    }

    var gapPosition: UInt32? {
        let mirror = Mirror(reflecting: self)
        return mirror.children.first(where: { $0.label == "gapPosition" })?.value as? UInt32
    }

    var gapLimit: UInt32? {
        let mirror = Mirror(reflecting: self)
        return mirror.children.first(where: { $0.label == "gapLimit" })?.value as? UInt32
    }
}
