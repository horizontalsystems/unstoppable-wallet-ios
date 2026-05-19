import EvmKit
import Foundation
import HdWalletKit
import MarketKit
import TronKit

public enum AccountType: Identifiable {
    case mnemonic(words: [String], salt: String, bip39Compliant: Bool)
    case passkeyOwned(credentialID: Data)
    case evmPrivateKey(data: Data)
    case trcPrivateKey(data: Data)
    case stellarSecretKey(secretSeed: String)
    case evmAddress(address: EvmKit.Address)
    case tronAddress(address: TronKit.Address)
    case tonAddress(address: String)
    case stellarAccount(accountId: String)
    case hdExtendedKey(key: HDExtendedKey)
    case btcAddress(address: String, blockchainType: BlockchainType, tokenType: TokenType)
    case moneroWatchAccount(address: String, viewKey: String)

    public var id: Self {
        self
    }
}

extension AccountType: Hashable {
    public static func == (lhs: AccountType, rhs: AccountType) -> Bool {
        switch (lhs, rhs) {
        case (let .mnemonic(lhsWords, lhsSalt, lhsBip39Compliant), let .mnemonic(rhsWords, rhsSalt, rhsBip39Compliant)):
            return lhsWords == rhsWords && lhsSalt == rhsSalt && lhsBip39Compliant == rhsBip39Compliant
        case let (.passkeyOwned(lhsCredentialID), .passkeyOwned(rhsCredentialID)):
            return lhsCredentialID == rhsCredentialID
        case let (.evmPrivateKey(lhsData), .evmPrivateKey(rhsData)):
            return lhsData == rhsData
        case let (.trcPrivateKey(lhsData), .trcPrivateKey(rhsData)):
            return lhsData == rhsData
        case let (.stellarSecretKey(lhsSecretSeed), .stellarSecretKey(rhsSecretSeed)):
            return lhsSecretSeed == rhsSecretSeed
        case let (.evmAddress(lhsAddress), .evmAddress(rhsAddress)):
            return lhsAddress == rhsAddress
        case let (.tronAddress(lhsAddress), .tronAddress(rhsAddress)):
            return lhsAddress == rhsAddress
        case let (.tonAddress(lhsAddress), .tonAddress(rhsAddress)):
            return lhsAddress == rhsAddress
        case let (.stellarAccount(lhsAccountId), .stellarAccount(rhsAccountId)):
            return lhsAccountId == rhsAccountId
        case let (.hdExtendedKey(lhsKey), .hdExtendedKey(rhsKey)):
            return lhsKey == rhsKey
        case let (.btcAddress(lhsAddress, lhsBlockchainType, lhsTokenType), .btcAddress(rhsAddress, rhsBlockchainType, rhsTokenType)):
            return lhsAddress == rhsAddress && lhsBlockchainType == rhsBlockchainType && lhsTokenType == rhsTokenType
        case let (.moneroWatchAccount(lhsAddress, lhsViewKey), .moneroWatchAccount(rhsAddress, rhsViewKey)):
            return lhsAddress == rhsAddress && lhsViewKey == rhsViewKey
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
        case let .passkeyOwned(credentialID):
            hasher.combine("passkeyOwned")
            hasher.combine(credentialID)
        case let .evmPrivateKey(data):
            hasher.combine("evmPrivateKey")
            hasher.combine(data)
        case let .trcPrivateKey(data):
            hasher.combine("trcPrivateKey")
            hasher.combine(data)
        case let .stellarSecretKey(secretSeed):
            hasher.combine("stellarSecretKey")
            hasher.combine(secretSeed)
        case let .evmAddress(address):
            hasher.combine("evmAddress")
            hasher.combine(address.raw)
        case let .tronAddress(address):
            hasher.combine("tronAddress")
            hasher.combine(address.raw)
        case let .tonAddress(address):
            hasher.combine("tonAddress")
            hasher.combine(address)
        case let .stellarAccount(accountId):
            hasher.combine("stellarAccount")
            hasher.combine(accountId)
        case let .hdExtendedKey(key):
            hasher.combine("hdExtendedKey")
            hasher.combine(key)
        case let .btcAddress(address, blockchainType, tokenType):
            hasher.combine("btcAddress")
            hasher.combine(address)
            hasher.combine(blockchainType)
            hasher.combine(tokenType)
        case let .moneroWatchAccount(address, viewKey):
            hasher.combine("moneroWatchWallet")
            hasher.combine(address)
            hasher.combine(viewKey)
        }
    }
}
