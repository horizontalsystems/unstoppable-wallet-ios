import EvmKit
import Foundation
import GRDB
import HsToolKit
import MarketKit
import Testing
@testable import Unstoppable

struct AccountTypePasskeyOwnedTests {
    @Test
    func supportsOnlyConfirmedV1Tokens() {
        let accountType = AccountType.passkeyOwned(
            credentialID: Data([0x01, 0x02, 0x03]),
            publicKeyX: Data(repeating: 0x11, count: 32),
            publicKeyY: Data(repeating: 0x22, count: 32)
        )

        #expect(accountType.supports(token: token(code: "USDT", blockchainType: .ethereum, tokenType: .eip20(address: "0xdAC17F958D2ee523a2206206994597C13D831ec7"))))
        #expect(accountType.supports(token: token(code: "USDC", blockchainType: .ethereum, tokenType: .eip20(address: "0xA0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"))))
        #expect(accountType.supports(token: token(code: "USDT", blockchainType: .binanceSmartChain, tokenType: .eip20(address: "0x55d398326f99059fF775485246999027B3197955"))))

        #expect(accountType.supports(token: token(code: "ETH", blockchainType: .ethereum, tokenType: .native)) == false)
        #expect(accountType.supports(token: token(code: "BNB", blockchainType: .binanceSmartChain, tokenType: .native)) == false)
        #expect(accountType.supports(token: token(code: "MATIC", blockchainType: .polygon, tokenType: .native)) == false)
        #expect(accountType.supports(token: token(code: "USDC", blockchainType: .base, tokenType: .eip20(address: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"))) == false)
    }

    @Test
    func exposesPasskeySpecificFlags() {
        let accountType = AccountType.passkeyOwned(
            credentialID: Data([0x01, 0x02, 0x03]),
            publicKeyX: Data(repeating: 0x11, count: 32),
            publicKeyY: Data(repeating: 0x22, count: 32)
        )

        #expect(accountType.mnemonicSeed == nil)
        #expect(accountType.canAddTokens == false)
        #expect(accountType.supportsWalletConnect == false)
        #expect(accountType.supportsTonConnect == false)
        #expect(accountType.watchAddress == nil)
        #expect(accountType.tronAddress == nil)
        #expect(accountType.sign(message: Data([0x01])) == nil)
        #expect(accountType.description == "Smart Wallet")
        #expect(accountType.statDescription == "passkey_owned")
    }

    @Test
    func evmAddressDerivesBarzCounterfactualOnSupportedChains() throws {
        let accountType = AccountType.passkeyOwned(
            credentialID: Data([0x01, 0x02, 0x03]),
            publicKeyX: Data(repeating: 0x11, count: 32),
            publicKeyY: Data(repeating: 0x22, count: 32)
        )

        let expected = try EvmKit.Address(hex: "0x9eab247c9c7406b1bb38a972730ce18c40046d30")
        #expect(accountType.evmAddress(chain: .ethereum) == expected)
        #expect(accountType.evmAddress(chain: .binanceSmartChain) == expected)
        #expect(accountType.evmAddress(chain: .polygon) == nil)
    }

    @Test
    func accountStorageRoundTripsPasskeyOwned() throws {
        let environment = try StorageTestEnvironment()
        let account = Account(
            id: UUID().uuidString,
            level: 3,
            name: "Passkey Wallet",
            type: .passkeyOwned(
                credentialID: Data([0x01, 0x02, 0x03, 0x04]),
                publicKeyX: Data(repeating: 0x11, count: 32),
                publicKeyY: Data(repeating: 0x22, count: 32)
            ),
            origin: .created,
            backedUp: false,
            fileBackedUp: false
        )

        environment.accountStorage.save(account: account)

        let (accounts, lostRecords) = environment.accountStorage.allAccounts
        let restored = try #require(accounts.first)

        #expect(lostRecords.isEmpty)
        #expect(accounts.count == 1)
        #expect(restored.id == account.id)
        #expect(restored.level == account.level)
        #expect(restored.name == account.name)
        #expect(restored.origin == account.origin)
        #expect(restored.backedUp == account.backedUp)
        #expect(restored.fileBackedUp == account.fileBackedUp)
        #expect(restored.type == account.type)
    }

    private func token(code: String, blockchainType: BlockchainType, tokenType: TokenType) -> Token {
        Token(
            coin: Coin(uid: "\(blockchainType.uid)-\(code.lowercased())", name: code, code: code),
            blockchain: Blockchain(type: blockchainType, name: blockchainType.uid, explorerUrl: nil),
            type: tokenType,
            decimals: 6
        )
    }
}

private struct StorageTestEnvironment {
    let accountStorage: AccountStorage

    init() throws {
        let logger = Logger(minLogLevel: .error)
        let keychainStorage = KeychainStorage(service: "account-storage-tests-\(UUID().uuidString)", logger: logger)
        let dbURL = FileManager.default.temporaryDirectory.appendingPathComponent("account-storage-tests-\(UUID().uuidString).sqlite")
        let dbPool = try DatabasePool(path: dbURL.path)

        try dbPool.write { db in
            try db.create(table: AccountRecord.databaseTableName) { table in
                table.column(AccountRecord.Columns.id.rawValue, .text).notNull().primaryKey()
                table.column(AccountRecord.Columns.level.rawValue, .integer).notNull()
                table.column(AccountRecord.Columns.name.rawValue, .text).notNull()
                table.column(AccountRecord.Columns.type.rawValue, .text).notNull()
                table.column(AccountRecord.Columns.origin.rawValue, .text).notNull()
                table.column(AccountRecord.Columns.backedUp.rawValue, .boolean).notNull()
                table.column(AccountRecord.Columns.fileBackedUp.rawValue, .boolean).notNull()
                table.column(AccountRecord.Columns.wordsKey.rawValue, .text)
                table.column(AccountRecord.Columns.saltKey.rawValue, .text)
                table.column(AccountRecord.Columns.dataKey.rawValue, .text)
                table.column(AccountRecord.Columns.bip39Compliant.rawValue, .boolean)
            }
        }

        let recordStorage = AccountRecordStorage(dbPool: dbPool)
        accountStorage = AccountStorage(keychainStorage: keychainStorage, storage: recordStorage)
    }
}
