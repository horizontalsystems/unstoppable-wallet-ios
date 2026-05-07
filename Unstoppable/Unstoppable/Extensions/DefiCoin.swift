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
