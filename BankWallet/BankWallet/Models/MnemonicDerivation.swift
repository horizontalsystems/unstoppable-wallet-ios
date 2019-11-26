enum MnemonicDerivation: String, CaseIterable {
    case bip44
    case bip49
    case bip84

    var title: String {
        switch self {
        case .bip44: return "BIP44"
        case .bip49: return "BIP49"
        case .bip84: return "BIP84"
        }
    }

    var description: String {
        switch self {
        case .bip44: return "Legacy"
        case .bip49: return "SegWit compatible"
        case .bip84: return "Native SegWit"
        }
    }

}
