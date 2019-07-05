import Foundation
import GRDB

enum AccountType {
    case mnemonic(words: [String], derivation: MnemonicDerivation, salt: String?)
    case privateKey(data: Data)
    case hdMasterKey(data: Data, derivation: MnemonicDerivation)
    case eos(account: String, activePrivateKey: Data)
}

extension AccountType: Equatable {

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

}

enum MnemonicDerivation: Int, DatabaseValueConvertible {

    case bip44
    case bip39

    public var databaseValue: DatabaseValue {
        return rawValue.databaseValue
    }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> MnemonicDerivation? {
        guard case .int64(let rawValue) = dbValue.storage else {
            return nil
        }
        return MnemonicDerivation(rawValue: Int(rawValue))
    }

}

