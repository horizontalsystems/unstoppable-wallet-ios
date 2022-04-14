import Foundation
import MarketKit
import BigInt

enum TransactionValue {
    case coinValue(platformCoin: PlatformCoin, value: Decimal)
    case tokenValue(tokenName: String, tokenCode: String, tokenDecimals: Int, value: Decimal)
    case rawValue(value: BigUInt)

    var coinName: String {
        switch self {
        case .coinValue(let platformCoin, _): return platformCoin.name
        case .tokenValue(let tokenName, _, _, _): return tokenName
        case .rawValue: return ""
        }
    }

    var coinCode: String {
        switch self {
        case .coinValue(let platformCoin, _): return platformCoin.code
        case .tokenValue(_, let tokenCode, _, _): return tokenCode
        case .rawValue: return ""
        }
    }

    var coin: Coin? {
        switch self {
        case .coinValue(let platformCoin, _): return platformCoin.coin
        case .tokenValue: return nil
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
        case .coinValue(let platformCoin, let value): return value.isMaxValue(decimals: platformCoin.decimals)
        case .tokenValue(_, _, let tokenDecimals, let value): return value.isMaxValue(decimals: tokenDecimals)
        case .rawValue: return false
        }
    }

    var abs: TransactionValue {
        switch self {
        case let .coinValue(platformCoin, value): return .coinValue(platformCoin: platformCoin, value: value.magnitude)
        case let .tokenValue(tokenName, tokenCode, tokenDecimals, value): return .tokenValue(tokenName: tokenName, tokenCode: tokenCode, tokenDecimals: tokenDecimals, value: value.magnitude)
        case let .rawValue(value): return .rawValue(value: value)
        }
    }

    var formattedString: String {
        switch self {
        case .coinValue, .tokenValue: return ValueFormatter.instance.format(transactionValue: self) ?? ""
        case .rawValue: return "n/a"
        }
    }

}

extension TransactionValue: Equatable {

    static func ==(lhs: TransactionValue, rhs: TransactionValue) -> Bool {
        switch (lhs, rhs) {
        case (.coinValue(let lhsPlatformCoin, let lhsValue), .coinValue(let rhsPlatformCoin, let rhsValue)): return lhsPlatformCoin == rhsPlatformCoin && lhsValue == rhsValue
        case (.tokenValue(let lhsTokenName, let lhsTokenCode, let lhsTokenDecimals, let lhsValue), .tokenValue(let rhsTokenName, let rhsTokenCode, let rhsTokenDecimals, let rhsValue)): return lhsTokenName == rhsTokenName && lhsTokenCode == rhsTokenCode && lhsTokenDecimals == rhsTokenDecimals && lhsValue == rhsValue
        case (.rawValue(let lhsValue), .rawValue(let rhsValue)): return lhsValue == rhsValue
        default: return false
        }
    }

}
