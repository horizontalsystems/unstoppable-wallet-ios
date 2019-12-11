enum MnemonicDerivation: String, CaseIterable {
    case bip44
    case bip49
    case bip84

    var title: String {
        switch self {
        case .bip44: return "Legacy - BIP44"
        case .bip49: return "SegWit - BIP49"
        case .bip84: return "Native SegWit - BIP84"
        }
    }

    var description: String {
        "coin_settings.derivation.description_\(self)".localized
    }

}
