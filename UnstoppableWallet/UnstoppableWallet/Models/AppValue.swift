import Foundation
import MarketKit
import StellarKit
import TonKit

struct AppValue {
    let kind: Kind
    let value: Decimal

    init(kind: Kind, value: Decimal) {
        self.kind = kind
        self.value = value
    }

    init(token: Token, value: Decimal) {
        kind = .token(token: token)
        self.value = value
    }

    init(tokenName: String, tokenCode: String, tokenDecimals: Int, value: Decimal) {
        kind = .eip20Token(tokenName: tokenName, tokenCode: tokenCode, tokenDecimals: tokenDecimals)
        self.value = value
    }

    init(jetton: Jetton, value: Decimal) {
        kind = .jetton(jetton: jetton)
        self.value = value
    }

    init(asset: Asset, value: Decimal) {
        kind = .stellar(asset: asset)
        self.value = value
    }

    init(nftUid: NftUid, tokenName: String?, tokenSymbol: String?, value: Decimal) {
        kind = .nft(nftUid: nftUid, tokenName: tokenName, tokenSymbol: tokenSymbol)
        self.value = value
    }

    init(value: Decimal) {
        kind = .raw
        self.value = value
    }

    var token: Token? {
        kind.token
    }

    var coin: Coin? {
        kind.coin
    }

    var name: String {
        switch kind {
        case let .token(token): return token.coin.name
        case let .coin(coin, _): return coin.name
        case let .eip20Token(tokenName, _, _): return tokenName
        case let .jetton(jetton): return jetton.name
        case let .stellar(asset): return asset.code
        case let .nft(nftUid, tokenName, _): return tokenName.map { "\($0) #\(nftUid.tokenId)" } ?? "#\(nftUid.tokenId)"
        case .raw: return ""
        }
    }

    var code: String {
        switch kind {
        case let .token(token): return token.coin.code
        case let .coin(coin, _): return coin.code
        case let .eip20Token(_, tokenCode, _): return tokenCode
        case let .jetton(jetton): return jetton.symbol
        case let .stellar(asset): return asset.code
        case let .nft(_, _, tokenSymbol): return tokenSymbol ?? "NFT"
        case .raw: return ""
        }
    }

    var decimals: Int? {
        switch kind {
        case let .token(token): return token.decimals
        case let .coin(_, decimals): return decimals
        case let .eip20Token(_, _, tokenDecimals): return tokenDecimals
        case let .jetton(jetton): return jetton.decimals
        case .stellar: return 7
        case .nft: return nil
        case .raw: return nil
        }
    }

    var isMaxValue: Bool {
        switch kind {
        case let .token(token):
            switch token.blockchain.type {
            case .stellar: return value == StellarAdapter.maxValue
            default: ()
            }
        case .stellar: return value == StellarAdapter.maxValue
        default: ()
        }

        return decimals.map { value.isMaxValue(decimals: $0) } ?? false
    }

    var tokenProtocol: TokenProtocol? {
        kind.tokenProtocol
    }

    var nftUid: NftUid? {
        switch kind {
        case let .nft(nftUid, _, _): return nftUid
        default: return nil
        }
    }

    var zeroValue: Bool {
        value == 0
    }

    var abs: AppValue {
        AppValue(kind: kind, value: value.magnitude)
    }

    var negative: AppValue {
        AppValue(kind: kind, value: Decimal(sign: .minus, exponent: value.exponent, significand: value.significand))
    }

    var infinity: String {
        "∞ \(code)"
    }

    func formattedFull(signType: ValueFormatter.SignType = .never) -> String? {
        switch kind {
        case let .token(token): return ValueFormatter.instance.formatFull(value: value, decimalCount: token.decimals, symbol: code, signType: signType)
        case let .coin(_, decimals): return ValueFormatter.instance.formatFull(value: value, decimalCount: decimals, symbol: code, signType: signType)
        case let .eip20Token(_, _, tokenDecimals): return ValueFormatter.instance.formatFull(value: value, decimalCount: tokenDecimals, symbol: code, signType: signType)
        case let .jetton(jetton): return ValueFormatter.instance.formatFull(value: value, decimalCount: jetton.decimals, symbol: code, signType: signType)
        case .stellar: return ValueFormatter.instance.formatFull(value: value, decimalCount: 7, symbol: code, signType: signType)
        case .nft: return "\(value.sign == .plus ? "+" : "")\(value) \(code)"
        case .raw: return nil
        }
    }

    func formattedShort(signType: ValueFormatter.SignType = .never) -> String? {
        switch kind {
        case let .token(token): return ValueFormatter.instance.formatShort(value: value, decimalCount: token.decimals, symbol: code, signType: signType)
        case let .coin(_, decimals): return ValueFormatter.instance.formatShort(value: value, decimalCount: decimals, symbol: code, signType: signType)
        case let .eip20Token(_, _, tokenDecimals): return ValueFormatter.instance.formatShort(value: value, decimalCount: tokenDecimals, symbol: code, signType: signType)
        case let .jetton(jetton): return ValueFormatter.instance.formatShort(value: value, decimalCount: jetton.decimals, symbol: code, signType: signType)
        case .stellar: return ValueFormatter.instance.formatShort(value: value, decimalCount: 7, symbol: code, signType: signType)
        case .nft: return "\(value.sign == .plus ? "+" : "")\(value) \(code)"
        case .raw: return nil
        }
    }
}

extension AppValue {
    enum Kind: Equatable {
        case token(token: Token)
        case coin(coin: Coin, decimals: Int)
        case eip20Token(tokenName: String, tokenCode: String, tokenDecimals: Int)
        case jetton(jetton: Jetton)
        case stellar(asset: Asset)
        case nft(nftUid: NftUid, tokenName: String?, tokenSymbol: String?)
        case raw

        var token: Token? {
            switch self {
            case let .token(token): return token
            default: return nil
            }
        }

        var coin: Coin? {
            switch self {
            case let .token(token): return token.coin
            case let .coin(coin, _): return coin
            default: return nil
            }
        }

        var tokenProtocol: TokenProtocol? {
            switch self {
            case let .token(token): return token.type.tokenProtocol
            case .eip20Token: return .eip20
            case .jetton: return .jetton
            case .stellar: return .stellar
            default: return nil
            }
        }

        static func == (lhs: Kind, rhs: Kind) -> Bool {
            switch (lhs, rhs) {
            case let (.token(lhsToken), .token(rhsToken)): return lhsToken == rhsToken
            case let (.coin(lhsCoin, lhsDecimals), .coin(rhsCoin, rhsDecimals)): return lhsCoin == rhsCoin && lhsDecimals == rhsDecimals
            case let (.eip20Token(lhsTokenName, lhsTokenCode, lhsTokenDecimals), .eip20Token(rhsTokenName, rhsTokenCode, rhsTokenDecimals)): return lhsTokenName == rhsTokenName && lhsTokenCode == rhsTokenCode && lhsTokenDecimals == rhsTokenDecimals
            case let (.jetton(lhsJetton), .jetton(rhsJetton)): return lhsJetton == rhsJetton
            case let (.stellar(lhsAsset), .stellar(rhsAsset)): return lhsAsset == rhsAsset
            case let (.nft(lhsNftUid, _, _), .nft(rhsNftUid, _, _)): return lhsNftUid == rhsNftUid
            case (.raw, .raw): return true
            default: return false
            }
        }
    }
}

extension AppValue: Equatable {
    static func == (lhs: AppValue, rhs: AppValue) -> Bool {
        lhs.kind == rhs.kind && lhs.value == rhs.value
    }
}
