import Foundation

enum AccountType {
    case mnemonic(words: [String], salt: String?)
    case privateKey(data: Data)
    case zcash(words: [String], birthdayHeight: Int?)
}

extension AccountType: Hashable {

    public static func ==(lhs: AccountType, rhs: AccountType) -> Bool {
        switch (lhs, rhs) {
        case (let .mnemonic(lhsWords, lhsSalt), let .mnemonic(rhsWords, rhsSalt)):
            return lhsWords == rhsWords && lhsSalt == rhsSalt
        case (let .privateKey(lhsData), let .privateKey(rhsData)):
            return lhsData == rhsData
        case (let .zcash(lhsWords, lhsHeight), let .zcash(rhsWords, rhsHeight)):
            return lhsWords == rhsWords && (lhsHeight ?? 0) == (rhsHeight ?? 0)
        default: return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case let .mnemonic(words, salt):
            hasher.combine(words)
            hasher.combine(salt)
        case let .privateKey(data):
            hasher.combine(data)
        case let .zcash(words, birthdayHeight):
            hasher.combine(words)
            if let height = birthdayHeight {
                hasher.combine(height)
            }
        }
    }

}
