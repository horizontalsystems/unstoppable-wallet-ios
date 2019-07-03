enum PredefinedAccountType: CaseIterable {
    case mnemonic
    case eos
    case binance

    var title: String {
        switch self {
        case .mnemonic: return "key_type.12_words"
        case .eos: return "key_type.eos"
        case .binance: return "key_type.24_words"
        }
    }

    var coinCodes: String {
        switch self {
        case .mnemonic: return "BTC, BCH, DASH, ETH, ERC-20"
        case .eos: return "EOS"
        case .binance: return "BNB"
        }
    }

}

extension AccountType {

    var predefinedAccountType: PredefinedAccountType? {
        switch self {
        case let .mnemonic(words, _, _):
            if words.count == 12 {
                return .mnemonic
            } else if words.count == 24 {
                return .binance
            }
        case .eos:
            return .eos
        default: ()
        }

        return nil
    }

}

extension CoinType {

    var predefinedAccountType: PredefinedAccountType {
        switch self {
        case .bitcoin, .bitcoinCash, .dash, .ethereum, .erc20:
            return .mnemonic
        case .eos:
            return .eos
        }
    }

}
