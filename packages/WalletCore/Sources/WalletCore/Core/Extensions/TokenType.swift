import MarketKit

public extension TokenType {
    var meta: String? {
        switch self {
        case let .derived(derivation): return derivation.rawValue
        case let .addressType(type): return type.rawValue
        case let .zanoAsset(id): return id
        default: return nil
        }
    }

    var tokenProtocol: TokenProtocol {
        switch self {
        case .native: return .native
        case .derived: return .native
        case .addressType: return .native
        case .eip20: return .eip20
        case .spl: return .spl
        case .jetton: return .jetton
        case .stellar: return .stellar
        case .zanoAsset: return .zanoAsset
        case .unsupported: return .unsupported
        }
    }
}
