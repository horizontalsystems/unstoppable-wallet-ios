import Foundation
import MarketKit
import BigInt

enum TransactionValue {
    case coinValue(token: Token, value: Decimal)
    case tokenValue(tokenName: String, tokenCode: String, tokenDecimals: Int, value: Decimal)
    case rawValue(value: BigUInt)

    var coinName: String {
        switch self {
        case .coinValue(let token, _): return token.coin.name
        case .tokenValue(let tokenName, _, _, _): return tokenName
        case .rawValue: return ""
        }
    }

    var coinCode: String {
        switch self {
        case .coinValue(let token, _): return token.coin.code
        case .tokenValue(_, let tokenCode, _, _): return tokenCode
        case .rawValue: return ""
        }
    }

    var coin: Coin? {
        switch self {
        case .coinValue(let token, _): return token.coin
        case .tokenValue: return nil
        case .rawValue: return nil
        }
    }

    var token: Token? {
        switch self {
        case .coinValue(let token, _): return token
        case .tokenValue: return Token()
        case .rawValue: return nil
        }
    }

    var tokenProtocol: TokenProtocol? {
        switch self {
        case .coinValue(let token, _): return token.type.tokenProtocol
        case .tokenValue: return .eip20
        case .rawValue: return nil
        }
    }

    var decimalValue: Decimal? {
        switch self {
        case .coinValue(_, let value): return value
        case .tokenValue(_, _, _, let value): return value
        case .rawValue: return nil
        }
    }

    var zeroValue: Bool {
        switch self {
        case .coinValue(_, let value): return value == 0
        case .tokenValue(_, _, _, let value): return value == 0
        case .rawValue(let value): return value == 0
        }
    }

    public var isMaxValue: Bool {
        switch self {
        case .coinValue(let token, let value): return value.isMaxValue(decimals: token.decimals)
        case .tokenValue(_, _, let tokenDecimals, let value): return value.isMaxValue(decimals: tokenDecimals)
        case .rawValue: return false
        }
    }

    func formattedFull(showSign: Bool = false) -> String? {
        switch self {
        case let .coinValue(token, value):
            return ValueFormatter.instance.formatFull(value: value, decimalCount: token.decimals, symbol: token.coin.code, showSign: showSign)
        case let .tokenValue(_, tokenCode, tokenDecimals, value):
            return ValueFormatter.instance.formatFull(value: value, decimalCount: tokenDecimals, symbol: tokenCode, showSign: showSign)
        case .rawValue:
            return nil
        }
    }

    func formattedShort(showSign: Bool = false) -> String? {
        switch self {
        case let .coinValue(token, value):
            return ValueFormatter.instance.formatShort(value: value, decimalCount: token.decimals, symbol: token.coin.code, showSign: showSign)
        case let .tokenValue(_, tokenCode, tokenDecimals, value):
            return ValueFormatter.instance.formatShort(value: value, decimalCount: tokenDecimals, symbol: tokenCode, showSign: showSign)
        case .rawValue:
            return nil
        }
    }

}

extension TransactionValue: Equatable {

    static func ==(lhs: TransactionValue, rhs: TransactionValue) -> Bool {
        switch (lhs, rhs) {
        case (.coinValue(let lhsToken, let lhsValue), .coinValue(let rhsToken, let rhsValue)): return lhsToken == rhsToken && lhsValue == rhsValue
        case (.tokenValue(let lhsTokenName, let lhsTokenCode, let lhsTokenDecimals, let lhsValue), .tokenValue(let rhsTokenName, let rhsTokenCode, let rhsTokenDecimals, let rhsValue)): return lhsTokenName == rhsTokenName && lhsTokenCode == rhsTokenCode && lhsTokenDecimals == rhsTokenDecimals && lhsValue == rhsValue
        case (.rawValue(let lhsValue), .rawValue(let rhsValue)): return lhsValue == rhsValue
        default: return false
        }
    }

}
