import BitcoinCore

extension ScriptType {
    var mnemonicDerivation: MnemonicDerivation? {
        switch self {
        case .p2pkh: return .bip44
        case .p2sh, .p2wpkhSh: return .bip49
        case .p2wsh, .p2wpkh: return .bip84
        case .p2tr: return .bip86
        default: return nil
        }
    }
}
