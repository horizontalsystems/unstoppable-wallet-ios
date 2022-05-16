import Foundation
import MarketKit
import BigInt

struct CoinValue {
    let kind: Kind
    let value: Decimal

    var isMaxValue: Bool {
        value.isMaxValue(decimals: kind.decimals)
    }

    var abs: CoinValue {
        CoinValue(kind: kind, value: value.magnitude)
    }

    var coin: Coin {
        kind.coin
    }

    var decimals: Int {
        kind.decimals
    }

}

extension CoinValue {

    enum Kind: Equatable {
        case platformCoin(platformCoin: PlatformCoin)
        case coin(coin: Coin, decimals: Int)

        var decimals: Int {
            switch self {
            case .platformCoin(let platformCoin): return platformCoin.platform.decimals
            case .coin(_, let decimals): return decimals
            }
        }

        var coin: Coin {
            switch self {
            case .platformCoin(let platformCoin): return platformCoin.coin
            case .coin(let coin, _): return coin
            }
        }

        static func ==(lhs: Kind, rhs: Kind) -> Bool {
            switch (lhs, rhs) {
            case (.platformCoin(let lhsPlatformCoin), .platformCoin(let rhsPlatformCoin)): return lhsPlatformCoin == rhsPlatformCoin
            case (.coin(let lhsCoin, let lhsDecimals), .coin(let rhsCoin, let rhsDecimals)): return lhsCoin == rhsCoin && lhsDecimals == rhsDecimals
            default: return false
            }
        }
    }

}

extension CoinValue: Equatable {

    public static func ==(lhs: CoinValue, rhs: CoinValue) -> Bool {
        lhs.kind == rhs.kind && lhs.value == rhs.value
    }

}
