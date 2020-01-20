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

    var description: String {
        "coin_settings.derivation.description_\(self)".localized
    }

}
