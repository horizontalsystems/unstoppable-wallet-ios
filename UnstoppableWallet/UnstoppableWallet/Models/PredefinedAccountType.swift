enum PredefinedAccountType: CaseIterable {
    case standard
    case binance
    case zCash
    case eos

    var title: String {
        switch self {
        case .standard: return "Standard"
        case .eos: return "EOS"
        case .binance: return "Binance"
        case .zCash: return "zCash"
        }
    }

    var coinCodes: String {
        switch self {
        case .standard: return "BTC, ETH, LTC, BCH, DASH, ERC20 tokens"
        case .eos: return "EOS, EOSIO tokens"
        case .binance: return "BNB, BEP2 tokens"
        case .zCash: return "ZEC"
        }
    }

    func supports(accountType: AccountType) -> Bool {
        switch self {
        case .standard:
            if case let .mnemonic(words, _) = accountType {
                return words.count == 12
            }
        case .eos:
            if case .eos = accountType {
                return true
            }
        case .binance:
            if case let .mnemonic(words, _) = accountType {
                return words.count == 24
            }
        case .zCash:
            if case let .mnemonic(words, _) = accountType {
                return words.count == 24
            }
        }

        return false
    }

    var createSupported: Bool {
        switch self {
        case .standard, .binance, .zCash: return true
        case .eos: return false
        }
    }

}

extension PredefinedAccountType: Hashable {

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .standard: hasher.combine("standard")
        case .eos: hasher.combine("eos")
        case .binance: hasher.combine("binance")
        case .zCash: hasher.combine("zCash")
        }
    }

}
