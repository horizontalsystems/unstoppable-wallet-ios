import Foundation

enum CoinType {
    case bitcoin
    case bitcoinCash
    case dash
    case ethereum
    case erc20(address: String, fee: Decimal)
    case eos(token: String, symbol: String)
    case binance(symbol: String)

    func canSupport(accountType: AccountType) -> Bool {
        switch self {
        case .bitcoin, .bitcoinCash, .dash, .ethereum, .erc20:
            if case let .mnemonic(words, derivation, salt) = accountType, words.count == 12, derivation == .bip44, salt == nil { return true }
            return false
        case .eos:
            if case .eos = accountType { return true }
            return false
        case .binance:
            if case let .mnemonic(words, derivation, salt) = accountType, words.count == 24, derivation == .bip44, salt == nil { return true }
            return false
        }
    }

    var defaultAccountType: DefaultAccountType {
        switch self {
        case .bitcoin, .bitcoinCash, .dash, .ethereum, .erc20:
            return .mnemonic(wordsCount: 12)
        case .eos:
            return .eos
        case .binance:
            return .mnemonic(wordsCount: 24)
        }
    }

}

extension CoinType: Equatable {

    public static func ==(lhs: CoinType, rhs: CoinType) -> Bool {
        switch (lhs, rhs) {
        case (.bitcoin, .bitcoin): return true
        case (.bitcoinCash, .bitcoinCash): return true
        case (.dash, .dash): return true
        case (.ethereum, .ethereum): return true
        case (.erc20(let lhsAddress, let lhsFee), .erc20(let rhsAddress, let rhsFee)):
            return lhsAddress == rhsAddress && lhsFee == rhsFee
        case (.eos(let lhsToken, let lhsSymbol), .eos(let rhsToken, let rhsSymbol)):
            return lhsToken == rhsToken && lhsSymbol == rhsSymbol
        case (.binance(let lhsSymbol), .binance(let rhsSymbol)):
            return lhsSymbol == rhsSymbol
        default: return false
        }
    }

}
