import BigInt
import Foundation
import MarketKit

enum TransactionValue {
    case coinValue(token: Token, value: Decimal)
    case tokenValue(tokenName: String, tokenCode: String, tokenDecimals: Int, value: Decimal)
    case nftValue(nftUid: NftUid, value: Decimal, tokenName: String?, tokenSymbol: String?)
    case rawValue(value: BigUInt)

    var fullName: String {
        switch self {
        case let .coinValue(token, _): return token.coin.name
        case let .tokenValue(tokenName, _, _, _): return tokenName
        case let .nftValue(nftUid, _, tokenName, _): return tokenName.map { "\($0) #\(nftUid.tokenId)" } ?? "#\(nftUid.tokenId)"
        case .rawValue: return ""
        }
    }

    var coinCode: String {
        switch self {
        case let .coinValue(token, _): return token.coin.code
        case let .tokenValue(_, tokenCode, _, _): return tokenCode
        case let .nftValue(_, _, _, tokenSymbol): return tokenSymbol ?? "NFT"
        case .rawValue: return ""
        }
    }

    var coin: Coin? {
        switch self {
        case let .coinValue(token, _): return token.coin
        default: return nil
        }
    }

    var token: Token? {
        switch self {
        case let .coinValue(token, _): return token
        default: return nil
        }
    }

    var tokenProtocol: TokenProtocol? {
        switch self {
        case let .coinValue(token, _): return token.type.tokenProtocol
        case .tokenValue: return .eip20
        case .nftValue: return nil
        case .rawValue: return nil
        }
    }

    var nftUid: NftUid? {
        switch self {
        case let .nftValue(nftUid, _, _, _): return nftUid
        default: return nil
        }
    }

    var decimalValue: Decimal? {
        switch self {
        case let .coinValue(_, value): return value
        case let .tokenValue(_, _, _, value): return value
        case let .nftValue(_, value, _, _): return value
        case .rawValue: return nil
        }
    }

    var zeroValue: Bool {
        switch self {
        case let .coinValue(_, value): return value == 0
        case let .tokenValue(_, _, _, value): return value == 0
        case let .nftValue(_, value, _, _): return value == 0
        case let .rawValue(value): return value == 0
        }
    }

    public var isMaxValue: Bool {
        switch self {
        case let .coinValue(token, value): return value.isMaxValue(decimals: token.decimals)
        case let .tokenValue(_, _, tokenDecimals, value): return value.isMaxValue(decimals: tokenDecimals)
        default: return false
        }
    }

    func formattedFull(signType: ValueFormatter.SignType = .never) -> String? {
        switch self {
        case let .coinValue(token, value):
            return ValueFormatter.instance.formatFull(value: value, decimalCount: token.decimals, symbol: token.coin.code, signType: signType)
        case let .tokenValue(_, tokenCode, tokenDecimals, value):
            return ValueFormatter.instance.formatFull(value: value, decimalCount: tokenDecimals, symbol: tokenCode, signType: signType)
        case let .nftValue(_, value, _, tokenSymbol):
            return "\(value.sign == .plus ? "+" : "")\(value) \(tokenSymbol ?? "NFT")"
        case .rawValue:
            return nil
        }
    }

    func formattedShort(signType: ValueFormatter.SignType = .never) -> String? {
        switch self {
        case let .coinValue(token, value):
            return ValueFormatter.instance.formatShort(value: value, decimalCount: token.decimals, symbol: token.coin.code, signType: signType)
        case let .tokenValue(_, tokenCode, tokenDecimals, value):
            return ValueFormatter.instance.formatShort(value: value, decimalCount: tokenDecimals, symbol: tokenCode, signType: signType)
        case let .nftValue(_, value, _, tokenSymbol):
            return "\(value.sign == .plus ? "+" : "")\(value) \(tokenSymbol ?? "NFT")"
        case .rawValue:
            return nil
        }
    }
}

extension TransactionValue: Equatable {
    static func == (lhs: TransactionValue, rhs: TransactionValue) -> Bool {
        switch (lhs, rhs) {
        case let (.coinValue(lhsToken, lhsValue), .coinValue(rhsToken, rhsValue)): return lhsToken == rhsToken && lhsValue == rhsValue
        case let (.tokenValue(lhsTokenName, lhsTokenCode, lhsTokenDecimals, lhsValue), .tokenValue(rhsTokenName, rhsTokenCode, rhsTokenDecimals, rhsValue)): return lhsTokenName == rhsTokenName && lhsTokenCode == rhsTokenCode && lhsTokenDecimals == rhsTokenDecimals && lhsValue == rhsValue
        case let (.nftValue(lhsNftUid, lhsValue, _, _), .nftValue(rhsNftUid, rhsValue, _, _)): return lhsNftUid == rhsNftUid && lhsValue == rhsValue
        case let (.rawValue(lhsValue), .rawValue(rhsValue)): return lhsValue == rhsValue
        default: return false
        }
    }
}
