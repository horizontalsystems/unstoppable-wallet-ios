import MarketKit

enum MnemonicDerivation: String, CaseIterable {
    case bip44
    case bip49
    case bip84

    var title: String {
        "\(addressType) - \(self.rawValue.uppercased())"
    }

    var addressType: String {
        switch self {
        case .bip44: return "Legacy"
        case .bip49: return "SegWit"
        case .bip84: return "Native SegWit"
        }
    }

    func description(coinType: CoinType) -> String {
        var description = "coin_settings.derivation.description.\(self)".localized

        if let addressPrefix = addressPrefix(coinType: coinType) {
            let startsWith = "coin_settings.derivation.starts_with".localized(addressPrefix)
            description += " (\(startsWith))"
        }

        return description
    }

    private func addressPrefix(coinType: CoinType) -> String? {
        switch coinType {
        case .bitcoin:
            switch self {
            case .bip44: return "1"
            case .bip49: return "3"
            case .bip84: return "bc1"
            }
        case .litecoin:
            switch self {
            case .bip44: return "L"
            case .bip49: return "M"
            case .bip84: return "ltc1"
            }
        default:
            return nil
        }
    }

}
