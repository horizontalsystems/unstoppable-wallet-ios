import Foundation
import HdWalletKit
import EthereumKit

enum AccountType {
    case mnemonic(words: [String], salt: String)
    case privateKey(data: Data)
    case address(address: EthereumKit.Address)

    var mnemonicSeed: Data? {
        switch self {
        case let .mnemonic(words, salt): return Mnemonic.seed(mnemonic: words, passphrase: salt)
        default: return nil
        }
    }

    var description: String {
        switch self {
        case .mnemonic(let words, let salt):
            let count = "\(words.count)"
            return salt.isEmpty ? "manage_accounts.n_words".localized(count) : "manage_accounts.n_words_with_passphrase".localized(count)
        case .address(let address):
            return address.eip55
        default:
            return ""
        }
    }

}

extension AccountType: Hashable {

    public static func ==(lhs: AccountType, rhs: AccountType) -> Bool {
        switch (lhs, rhs) {
        case (let .mnemonic(lhsWords, lhsSalt), let .mnemonic(rhsWords, rhsSalt)):
            return lhsWords == rhsWords && lhsSalt == rhsSalt
        case (let .privateKey(lhsData), let .privateKey(rhsData)):
            return lhsData == rhsData
        case (let .address(lhsAddress), let .address(rhsAddress)):
            return lhsAddress == rhsAddress
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
        case let .address(address):
            hasher.combine(address.raw)
        }
    }

}
