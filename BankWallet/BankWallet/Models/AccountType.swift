import Foundation

enum AccountType {
    case mnemonic(words: [String], derivation: MnemonicDerivation, salt: String?)
    case privateKey(data: Data)
    case hdMasterKey(data: Data, derivation: MnemonicDerivation)
    case eos(account: String, activePrivateKey: String)
}

extension AccountType: Hashable {

    public static func ==(lhs: AccountType, rhs: AccountType) -> Bool {
        switch (lhs, rhs) {
        case (let .mnemonic(lhsWords, lhsDerivation, lhsSalt), let .mnemonic(rhsWords, rhsDerivation, rhsSalt)):
            return lhsWords == rhsWords && lhsDerivation == rhsDerivation && lhsSalt == rhsSalt
        case (let .privateKey(lhsData), let .privateKey(rhsData)):
            return lhsData == rhsData
        case (let .hdMasterKey(lhsData, lhsDerivation), let .hdMasterKey(rhsData, rhsDerivation)):
            return lhsData == rhsData && lhsDerivation == rhsDerivation
        case (let .eos(lhsAccount, lhsActivePrivateKey), let .eos(rhsAccount, rhsActivePrivateKey)):
            return lhsAccount == rhsAccount && lhsActivePrivateKey == rhsActivePrivateKey
        default: return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case let .mnemonic(words, derivation, salt):
            hasher.combine(words)
            hasher.combine(derivation)
            hasher.combine(salt)
        case let .privateKey(data):
            hasher.combine(data)
        case let .hdMasterKey(data, derivation):
            hasher.combine(data)
            hasher.combine(derivation)
        case let .eos(account, activePrivateKey):
            hasher.combine(account)
            hasher.combine(activePrivateKey)
        }
    }

}

enum MnemonicDerivation: String {
    case bip44
    case bip49
}
