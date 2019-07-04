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

enum TypeNames: Int, DatabaseValueConvertible {
    case mnemonic
    case privateKey
    case hdMasterKey
    case eos

    public var databaseValue: DatabaseValue {
        return rawValue.databaseValue
    }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> TypeNames? {
        guard case .int64(let rawValue) = dbValue.storage else {
            return nil
        }
        return TypeNames(rawValue: Int(rawValue))
    }

}

final class EncryptedStringArray: DatabaseValueConvertible {
    var array: [String]

    init(array: [String]) {
        self.array = array
    }

    public var databaseValue: DatabaseValue {
        var encryptedData = Data()
        if let stringData = array.joined(separator: ",").data(using: .utf8) {
            encryptedData = (try? EncryptionHelper.shared.encrypt(data: stringData)) ?? Data()
        }
        return encryptedData.databaseValue
    }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> EncryptedStringArray? {
        guard case .blob(let encryptedData) = dbValue.storage else {
            return nil
        }
        if let stringData = try? EncryptionHelper.shared.decrypt(data: encryptedData), let string = String(data: stringData, encoding: .utf8) {
            return .init(array: string.split(separator: ",").map { String($0) })
        }

        return nil
    }

}

final class EncryptedString: DatabaseValueConvertible {
    var string: String

    init?(string: String?) {
        guard let string = string else {
            return nil
        }
        self.string = string
    }

    public var databaseValue: DatabaseValue {
        var encryptedData = Data()
        if let stringData = string.data(using: .utf8) {
            encryptedData = (try? EncryptionHelper.shared.encrypt(data: stringData)) ?? Data()
        }
        return encryptedData.databaseValue
    }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> EncryptedString? {
        guard case .blob(let encryptedData) = dbValue.storage else {
            return nil
        }
        if let stringData = try? EncryptionHelper.shared.decrypt(data: encryptedData) {
            return EncryptedString(string: String(data: stringData, encoding: .utf8))
        }

        return nil
    }

}

final class EncryptedData: DatabaseValueConvertible {
    var data: Data

    init(data: Data) {
        self.data = data
    }

    public var databaseValue: DatabaseValue {
        var encryptedData = Data()
        if let data = try? EncryptionHelper.shared.encrypt(data: data) {
            encryptedData = data
        }
        return encryptedData.databaseValue
    }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> EncryptedData? {
        guard case .blob(let encryptedData) = dbValue.storage else {
            return nil
        }
        if let decryptedData = try? EncryptionHelper.shared.decrypt(data: encryptedData) {
            return .init(data: decryptedData)
        }

        return nil
    }

}
