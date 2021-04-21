import Foundation

enum AccountType {
    case mnemonic(words: [String], salt: String)
    case privateKey(data: Data)
}

extension AccountType: Hashable {

    public static func ==(lhs: AccountType, rhs: AccountType) -> Bool {
        switch (lhs, rhs) {
        case (let .mnemonic(lhsWords, lhsSalt), let .mnemonic(rhsWords, rhsSalt)):
            return lhsWords == rhsWords && lhsSalt == rhsSalt
        case (let .privateKey(lhsData), let .privateKey(rhsData)):
            return lhsData == rhsData
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
        }
    }

}
