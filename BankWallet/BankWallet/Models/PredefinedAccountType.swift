enum PredefinedAccountType: CaseIterable {
    case standard
    case eos
    case binance

    var title: String {
        switch self {
        case .standard: return "Standard"
        case .eos: return "EOS"
        case .binance: return "Binance"
        }
    }

    var coinCodes: String {
        switch self {
        case .standard: return "BTC, ETH, BCH, DASH, ERC20 tokens"
        case .eos: return "EOS, EOS tokens"
        case .binance: return "BNB, BEP-2 tokens"
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
        }

        return false
    }

}

extension PredefinedAccountType: Hashable {

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .standard: hasher.combine("standard")
        case .eos: hasher.combine("eos")
        case .binance: hasher.combine("binance")
        }
    }

}
