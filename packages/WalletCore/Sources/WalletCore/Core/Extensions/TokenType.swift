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
}
