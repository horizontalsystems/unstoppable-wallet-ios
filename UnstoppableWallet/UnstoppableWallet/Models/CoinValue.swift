import BigInt
import Foundation
import MarketKit

struct CoinValue {
    let kind: Kind
    let value: Decimal

    var isMaxValue: Bool {
        value.isMaxValue(decimals: kind.decimals)
    }

    var abs: CoinValue {
        CoinValue(kind: kind, value: value.magnitude)
    }

    var symbol: String {
        kind.symbol
    }

    var decimals: Int {
        kind.decimals
    }

    var formattedFull: String? {
        ValueFormatter.instance.formatFull(coinValue: self)
    }

    var formattedShort: String? {
        ValueFormatter.instance.formatShort(coinValue: self)
    }

    var infinity: String {
        "∞ \(kind.symbol)"
    }
}

extension CoinValue {
    enum Kind: Equatable {
        case token(token: Token)
        case coin(coin: Coin, decimals: Int)
        case cexAsset(cexAsset: CexAsset)

        var token: Token? {
            switch self {
            case let .token(token): return token
            case .coin, .cexAsset: return nil
            }
        }

        var decimals: Int {
            switch self {
            case let .token(token): return token.decimals
            case let .coin(_, decimals): return decimals
            case .cexAsset: return CexAsset.decimals
            }
        }

        var symbol: String {
            switch self {
            case let .token(token): return token.coin.code
            case let .coin(coin, _): return coin.code
            case let .cexAsset(cexAsset): return cexAsset.coinCode
            }
        }

        static func == (lhs: Kind, rhs: Kind) -> Bool {
            switch (lhs, rhs) {
            case let (.token(lhsToken), .token(rhsToken)): return lhsToken == rhsToken
            case let (.coin(lhsCoin, lhsDecimals), .coin(rhsCoin, rhsDecimals)): return lhsCoin == rhsCoin && lhsDecimals == rhsDecimals
            case let (.cexAsset(lhsCexAsset), .cexAsset(rhsCexAsset)): return lhsCexAsset == rhsCexAsset
            default: return false
            }
        }
    }
}

extension CoinValue: Equatable {
    public static func == (lhs: CoinValue, rhs: CoinValue) -> Bool {
        lhs.kind == rhs.kind && lhs.value == rhs.value
    }
}
