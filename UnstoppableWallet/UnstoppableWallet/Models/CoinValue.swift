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

    var symbol: String {
        kind.symbol
    }

    var decimals: Int {
        kind.decimals
    }

    var formattedFull: String? {
        ValueFormatter.instance.formatFull(coinValue: self)
    }

}

extension CoinValue {

    enum Kind: Equatable {
        case token(token: Token)
        case coin(coin: Coin, decimals: Int)
        case cexAsset(cexAsset: CexAsset)

        var token: Token? {
            switch self {
                case .token(let token): return token
                case .coin, .cexAsset: return nil
            }
        }

        var decimals: Int {
            switch self {
            case .token(let token): return token.decimals
            case .coin(_, let decimals): return decimals
            case .cexAsset: return CexAsset.decimals
            }
        }

        var symbol: String {
            switch self {
            case .token(let token): return token.coin.code
            case .coin(let coin, _): return coin.code
            case .cexAsset(let cexAsset): return cexAsset.coinCode
            }
        }

        static func ==(lhs: Kind, rhs: Kind) -> Bool {
            switch (lhs, rhs) {
            case (.token(let lhsToken), .token(let rhsToken)): return lhsToken == rhsToken
            case (.coin(let lhsCoin, let lhsDecimals), .coin(let rhsCoin, let rhsDecimals)): return lhsCoin == rhsCoin && lhsDecimals == rhsDecimals
            case (.cexAsset(let lhsCexAsset), .cexAsset(let rhsCexAsset)): return lhsCexAsset == rhsCexAsset
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
