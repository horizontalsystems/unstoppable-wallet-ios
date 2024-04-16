import BitcoinCore
import Crypto
import EvmKit
import Foundation
import HdWalletKit
import MarketKit
import TronKit

enum AccountType {
    case mnemonic(words: [String], salt: String, bip39Compliant: Bool)
    case evmPrivateKey(data: Data)
    case evmAddress(address: EvmKit.Address)
    case tronAddress(address: TronKit.Address)
    case tonAddress(address: String)
    case hdExtendedKey(key: HDExtendedKey)
    case btcAddress(address: String, blockchainType: BlockchainType, tokenType: TokenType)
    case cex(cexAccount: CexAccount)

    var mnemonicSeed: Data? {
        switch self {
        case let .mnemonic(words, salt, bip39Compliant):
            return bip39Compliant
                ? Mnemonic.seed(mnemonic: words, passphrase: salt)
                : Mnemonic.seedNonStandard(mnemonic: words, passphrase: salt)

        default: return nil
        }
    }

    func uniqueId(hashed: Bool = true) -> Data {
        let privateData: Data
        switch self {
        case let .mnemonic(words, salt, bip39Compliant):
            var description = words.joined(separator: " ")
            if !bip39Compliant {
                description += "&nonBip39Compliant"
            }
            if !salt.isEmpty {
                description += "@" + salt
            }

            privateData = description.data(using: .utf8) ?? Data() // always non-null
        case let .evmPrivateKey(data):
            privateData = data
        case let .evmAddress(address):
            privateData = address.hex.hs.data
        case let .tronAddress(address):
            privateData = address.hex.hs.data
        case let .tonAddress(address):
            privateData = address.hs.data
        case let .hdExtendedKey(key):
            privateData = key.serialized
        case let .btcAddress(address, blockchainType, tokenType):
            privateData = "\(address)&\(blockchainType.uid)|\(tokenType.id)".data(using: .utf8) ?? Data()
        case let .cex(cexAccount):
            privateData = cexAccount.uniqueId.data(using: .utf8) ?? Data() // always non-null
        }

        if hashed {
            return Data(SHA512.hash(data: privateData))
        } else {
            return privateData
        }
    }

    func supports(token: Token) -> Bool {
        switch self {
        case .mnemonic:
            switch (token.blockchainType, token.type) {
            case (.bitcoin, .derived): return true
            case (.bitcoinCash, .addressType): return true
            case (.ecash, .native): return true
            case (.litecoin, .derived): return true
            case (.dash, .native): return true
            case (.zcash, .native): return true
            case (.binanceChain, .native), (.binanceChain, .bep2): return true
            case (.ethereum, .native), (.ethereum, .eip20): return true
            case (.binanceSmartChain, .native), (.binanceSmartChain, .eip20): return true
            case (.polygon, .native), (.polygon, .eip20): return true
            case (.avalanche, .native), (.avalanche, .eip20): return true
            case (.gnosis, .native), (.gnosis, .eip20): return true
            case (.fantom, .native), (.fantom, .eip20): return true
            case (.arbitrumOne, .native), (.arbitrumOne, .eip20): return true
            case (.optimism, .native), (.optimism, .eip20): return true
            case (.tron, .native), (.tron, .eip20): return true
            case (.ton, .native): return true
            default: return false
            }
        case let .hdExtendedKey(key):
            switch token.blockchainType {
            case .bitcoin, .litecoin:
                guard let derivation = token.type.derivation, key.purposes.contains(where: { $0.mnemonicDerivation == derivation }) else {
                    return false
                }

                if token.blockchainType == .bitcoin {
                    return key.coinTypes.contains(where: { $0 == .bitcoin })
                }

                return key.coinTypes.contains(where: { $0 == .litecoin })
            case .bitcoinCash, .ecash, .dash:
                return key.purposes.contains(where: { $0 == .bip44 })
            default:
                return false
            }
        case .evmPrivateKey, .evmAddress:
            switch (token.blockchainType, token.type) {
            case (.ethereum, .native), (.ethereum, .eip20): return true
            case (.binanceSmartChain, .native), (.binanceSmartChain, .eip20): return true
            case (.polygon, .native), (.polygon, .eip20): return true
            case (.avalanche, .native), (.avalanche, .eip20): return true
            case (.gnosis, .native), (.gnosis, .eip20): return true
            case (.fantom, .native), (.fantom, .eip20): return true
            case (.arbitrumOne, .native), (.arbitrumOne, .eip20): return true
            case (.optimism, .native), (.optimism, .eip20): return true
            default: return false
            }
        case .tronAddress:
            switch (token.blockchainType, token.type) {
            case (.tron, .native), (.tron, .eip20): return true
            default: return false
            }
        case .tonAddress:
            switch (token.blockchainType, token.type) {
            case (.ton, .native): return true
            default: return false
            }
        case let .btcAddress(_, blockchainType, tokenType):
            return token.blockchainType == blockchainType && token.type == tokenType

        default:
            return false
        }
    }

    var canAddTokens: Bool {
        switch self {
        case .mnemonic, .evmPrivateKey: return true
        default: return false
        }
    }

    var supportsWalletConnect: Bool {
        switch self {
        case .mnemonic, .evmPrivateKey: return true
        default: return false
        }
    }

    var supportsNft: Bool {
        switch self {
        case .cex: return false
        default: return true
        }
    }

    var withdrawalAllowed: Bool {
        switch self {
        case let .cex(cexAccount: account): return account.cex.withdrawalAllowed
        default: return true
        }
    }

    var description: String {
        switch self {
        case let .mnemonic(words, salt, _):
            let count = "\(words.count)"
            return salt.isEmpty ? "manage_accounts.n_words".localized(count) : "manage_accounts.n_words_with_passphrase".localized(count)
        case .evmPrivateKey:
            return "EVM Private Key"
        case .evmAddress:
            return "EVM Address"
        case .tronAddress:
            return "TRON Address"
        case .tonAddress:
            return "TON Address"
        case let .hdExtendedKey(key):
            switch key {
            case .private:
                switch key.derivedType {
                case .master: return "BIP32 Root Key"
                case .account: return "Account xPrivKey"
                default: return ""
                }
            case .public:
                switch key.derivedType {
                case .account: return "Account xPubKey"
                default: return ""
                }
            }
        case .btcAddress:
            return "BTC Address"
        case let .cex(cexAccount):
            return cexAccount.cex.title
        }
    }

    var statDescription: String {
        switch self {
        case let .mnemonic(words, salt, _):
            let count = "\(words.count)"
            return salt.isEmpty ? "mnemonic_\(count)" : "mnemonic_with_passphrase_\(count)"
        case .evmPrivateKey:
            return "evm_private_key"
        case .evmAddress:
            return "evm_address"
        case .tronAddress:
            return "tron_address"
        case .tonAddress:
            return "ton_address"
        case let .hdExtendedKey(key):
            switch key {
            case .private:
                switch key.derivedType {
                case .master: return "bip32_root_key"
                case .account: return "account_x_priv_key"
                default: return ""
                }
            case .public:
                switch key.derivedType {
                case .account: return "account_x_pub_key"
                default: return ""
                }
            }
        case .btcAddress:
            return "btc_address"
        case .cex:
            return "cex"
        }
    }

    var detailedDescription: String {
        switch self {
        case let .evmAddress(address):
            return address.eip55.shortened
        case let .tronAddress(address):
            return address.base58.shortened
        case let .tonAddress(address):
            return address.shortened
        case let .btcAddress(address, _, _):
            return address.shortened
        default: return description
        }
    }

    func evmAddress(chain: Chain) -> EvmKit.Address? {
        switch self {
        case .mnemonic:
            guard let mnemonicSeed else {
                return nil
            }

            return try? Signer.address(seed: mnemonicSeed, chain: chain)
        case let .evmPrivateKey(data):
            return Signer.address(privateKey: data)
        default:
            return nil
        }
    }

    func sign(message: Data, isLegacy: Bool = false) -> Data? {
        switch self {
        case .mnemonic:
            guard let mnemonicSeed else {
                return nil
            }

            guard let privateKey = try? Signer.privateKey(seed: mnemonicSeed, chain: App.shared.evmBlockchainManager.chain(blockchainType: .ethereum)) else {
                return nil
            }

            return try? EvmKit.Kit.sign(message: message, privateKey: privateKey, isLegacy: isLegacy)
        case let .evmPrivateKey(data):
            return try? EvmKit.Kit.sign(message: message, privateKey: data, isLegacy: isLegacy)
        default:
            return nil
        }
    }
}

extension AccountType {
    private static func split(_ string: String, separator: String) -> (String, String) {
        if let index = string.firstIndex(of: Character(separator)) {
            let left = String(string.prefix(upTo: index))
            let right = String(string.suffix(from: string.index(after: index)))
            return (left, right)
        }

        return (string, "")
    }

    static func decode(uniqueId: Data, type: Abstract) -> AccountType? {
        let string = String(decoding: uniqueId, as: UTF8.self)

        switch type {
        case .mnemonic:
            let (wordsWithCompliant, salt) = split(string, separator: "@")
            let (wordList, bip39CompliantString) = split(wordsWithCompliant, separator: "&")
            let words = wordList.split(separator: " ").map(String.init)

            let bip39Compliant = bip39CompliantString.isEmpty
            return AccountType.mnemonic(words: words, salt: salt, bip39Compliant: bip39Compliant)
        case .evmPrivateKey:
            return AccountType.evmPrivateKey(data: uniqueId)
        case .hdExtendedKey:
            do {
                return try AccountType.hdExtendedKey(key: HDExtendedKey(data: uniqueId))
            } catch {
                return nil
            }
        case .btcAddress:
            let (address, details) = split(string, separator: "&")
            let (tokenTypeValue, blockchainTypeUid) = split(details, separator: "|")
            guard let tokenType = TokenType(id: tokenTypeValue) else {
                return nil
            }

            return AccountType.btcAddress(address: address, blockchainType: BlockchainType(uid: blockchainTypeUid), tokenType: tokenType)
        case .evmAddress:
            return (try? EvmKit.Address(hex: string)).map { AccountType.evmAddress(address: $0) }
        case .tronAddress:
            let hexData = Data(hex: string)
            
            let address: TronKit.Address?
            if !hexData.isEmpty {           // android convention address
                address = try? TronKit.Address(raw: hexData)
            } else {                        // old ios style
                address = try? TronKit.Address(address: string)
            }
            
            return address.map { AccountType.tronAddress(address: $0) }
        case .tonAddress:
            return AccountType.tonAddress(address: string)
        case .cex:
            guard let cexAccount = CexAccount.decode(uniqueId: string) else {
                return nil
            }

            return .cex(cexAccount: cexAccount)
        }
    }

    enum Abstract: String, Codable {
        case mnemonic
        case evmPrivateKey = "private_key"
        case evmAddress = "evm_address"
        case tronAddress = "tron_address"
        case tonAddress = "ton_address"
        case hdExtendedKey = "hd_extended_key"
        case btcAddress = "btc_address_key"
        case cex

        init(_ type: AccountType) {
            switch type {
            case .mnemonic: self = .mnemonic
            case .evmPrivateKey: self = .evmPrivateKey
            case .evmAddress: self = .evmAddress
            case .tronAddress: self = .tronAddress
            case .tonAddress: self = .tonAddress
            case .hdExtendedKey: self = .hdExtendedKey
            case .btcAddress: self = .btcAddress
            case .cex: self = .cex
            }
        }
    }
}

extension AccountType: Hashable {
    public static func == (lhs: AccountType, rhs: AccountType) -> Bool {
        switch (lhs, rhs) {
        case (let .mnemonic(lhsWords, lhsSalt, lhsBip39Compliant), let .mnemonic(rhsWords, rhsSalt, rhsBip39Compliant)):
            return lhsWords == rhsWords && lhsSalt == rhsSalt && lhsBip39Compliant == rhsBip39Compliant
        case let (.evmPrivateKey(lhsData), .evmPrivateKey(rhsData)):
            return lhsData == rhsData
        case let (.evmAddress(lhsAddress), .evmAddress(rhsAddress)):
            return lhsAddress == rhsAddress
        case let (.tronAddress(lhsAddress), .tronAddress(rhsAddress)):
            return lhsAddress == rhsAddress
        case let (.tonAddress(lhsAddress), .tonAddress(rhsAddress)):
            return lhsAddress == rhsAddress
        case let (.hdExtendedKey(lhsKey), .hdExtendedKey(rhsKey)):
            return lhsKey == rhsKey
        case let (.btcAddress(lhsAddress, lhsBlockchainType, lhsTokenType), .btcAddress(rhsAddress, rhsBlockchainType, rhsTokenType)):
            return lhsAddress == rhsAddress && lhsBlockchainType == rhsBlockchainType && lhsTokenType == rhsTokenType
        case let (.cex(lhsCexAccount), .cex(rhsCexAccount)):
            return lhsCexAccount == rhsCexAccount
        default: return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case let .mnemonic(words, salt, bip39Compliant):
            hasher.combine("mnemonic")
            hasher.combine(words)
            hasher.combine(salt)
            hasher.combine(bip39Compliant)
        case let .evmPrivateKey(data):
            hasher.combine("evmPrivateKey")
            hasher.combine(data)
        case let .evmAddress(address):
            hasher.combine("evmAddress")
            hasher.combine(address.raw)
        case let .tronAddress(address):
            hasher.combine("tronAddress")
            hasher.combine(address.raw)
        case let .tonAddress(address):
            hasher.combine("tonAddress")
            hasher.combine(address)
        case let .hdExtendedKey(key):
            hasher.combine("hdExtendedKey")
            hasher.combine(key)
        case let .btcAddress(address, blockchainType, tokenType):
            hasher.combine("btcAddress")
            hasher.combine(address)
            hasher.combine(blockchainType)
            hasher.combine(tokenType)
        case let .cex(cexAccount):
            hasher.combine("cex")
            hasher.combine(cexAccount)
        }
    }
}

extension AccountType {
    static func decrypt(crypto: BackupCrypto, type: AccountType.Abstract, passphrase: String) throws -> AccountType {
        let data = try crypto.decrypt(passphrase: passphrase)

        guard let accountType = AccountType.decode(uniqueId: data, type: type) else {
            throw RestoreCloudModule.RestoreError.invalidBackup
        }

        return accountType
    }
}
