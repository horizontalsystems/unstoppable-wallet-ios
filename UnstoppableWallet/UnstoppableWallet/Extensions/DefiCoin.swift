import Foundation
import MarketKit

extension DefiCoin {
    var name: String {
        switch type {
        case let .defiCoin(name, _): return name
        case let .fullCoin(fullCoin): return fullCoin.coin.name
        }
    }
}

extension DefiCoin: Hashable {
    public static func == (lhs: DefiCoin, rhs: DefiCoin) -> Bool {
        lhs.uid == rhs.uid
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(uid)
    }
}
