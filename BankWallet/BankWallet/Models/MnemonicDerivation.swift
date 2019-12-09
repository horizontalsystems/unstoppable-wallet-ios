enum MnemonicDerivation: String, CaseIterable {
    case bip44
    case bip49
    case bip84

    var title: String {
        switch self {
        case .bip44: return "BIP44 | Legacy"
        case .bip49: return "BIP49 | SegWit"
        case .bip84: return "BIP84 | Native SegWit"
        }
    }

    var description: String {
        "coin_settings.derivation.description_\(self)".localized
    }

}
