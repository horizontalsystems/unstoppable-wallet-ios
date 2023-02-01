import MarketKit

extension TokenType {

    var tokenProtocol: TokenProtocol {
        switch self {
        case .native: return .native
        case .eip20: return .eip20
        case .bep2: return .bep2
        case .spl: return .spl
        case .unsupported: return .unsupported
        }
    }

    var bep2Symbol: String? {
        switch self {
        case .bep2(let symbol): return symbol
        default: return nil
        }
    }

    var order: Int {
        switch self {
        case .native: return 0
        default: return 1
        }
    }

}
