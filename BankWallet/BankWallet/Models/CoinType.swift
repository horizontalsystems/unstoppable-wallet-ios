import Foundation

enum CoinType {
    case bitcoin
    case bitcoinCash
    case dash
    case ethereum
    case erc20(address: String, fee: Decimal, gasLimit: Int?, minimumRequiredBalance: Decimal)
    case eos(token: String, symbol: String)
    case binance(symbol: String)

    init(erc20Address: String, fee: Decimal = 0, gasLimit: Int? = nil, minimumRequiredBalance: Decimal = 0) {
        self = .erc20(address: erc20Address, fee: fee, gasLimit: gasLimit, minimumRequiredBalance: minimumRequiredBalance)
    }

    func canSupport(accountType: AccountType) -> Bool {
        switch self {
        case .bitcoin, .bitcoinCash, .dash, .ethereum, .erc20:
            if case let .mnemonic(words, _, salt) = accountType, words.count == 12, salt == nil { return true }
            return false
        case .eos:
            if case .eos = accountType { return true }
            return false
        case .binance:
            if case let .mnemonic(words, _, salt) = accountType, words.count == 24, salt == nil { return true }
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

    var blockchainType: String? {
        switch self {
        case .erc20: return "ERC20"
        case .eos(let token, _):
            if token != "eosio.token" {
                return "EOSIO"
            }
        case .binance(let symbol):
            if symbol != "BNB" {
                return "BEP2"
            }
        default: ()
        }

        return nil
    }

}

extension CoinType: Equatable {

    public static func ==(lhs: CoinType, rhs: CoinType) -> Bool {
        switch (lhs, rhs) {
        case (.bitcoin, .bitcoin): return true
        case (.bitcoinCash, .bitcoinCash): return true
        case (.dash, .dash): return true
        case (.ethereum, .ethereum): return true
        case (.erc20(let lhsAddress, let lhsFee, let lhsGasLimit, _), .erc20(let rhsAddress, let rhsFee, let rhsGasLimit, _)):
            return lhsAddress == rhsAddress && lhsFee == rhsFee && lhsGasLimit == rhsGasLimit
        case (.eos(let lhsToken, let lhsSymbol), .eos(let rhsToken, let rhsSymbol)):
            return lhsToken == rhsToken && lhsSymbol == rhsSymbol
        case (.binance(let lhsSymbol), .binance(let rhsSymbol)):
            return lhsSymbol == rhsSymbol
        default: return false
        }
    }

}
