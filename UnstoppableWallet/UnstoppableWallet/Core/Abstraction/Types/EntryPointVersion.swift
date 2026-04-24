import EvmKit
import Foundation

public enum EntryPointVersion: String, Codable, Hashable {
    case v06
    case v07
    case v08
}

public extension EntryPointVersion {
    var address: EvmKit.Address {
        switch self {
        case .v06:
            return try! EvmKit.Address(hex: "0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789")
        case .v07:
            return try! EvmKit.Address(hex: "0x0000000071727De22E5E9d8BAf0edAc6f37da032")
        case .v08:
            return try! EvmKit.Address(hex: "0x4337084D9E255Ff0702461CF8895CE9E3b5Ff108")
        }
    }
}
