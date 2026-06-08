import EvmKit
import Foundation
import GRDB
import HsToolKit
import MarketKit
import Testing
@testable import Unstoppable
@testable import WalletCore

struct AccountTypePasskeyOwnedTests {
    @Test
    func supportsOnlyConfirmedV1Tokens() {
        let accountType = AccountType.passkeyOwned(
            credentialID: Data([0x01, 0x02, 0x03])
        )

        #expect(accountType.supports(token: token(code: "USDT", blockchainType: .ethereum, tokenType: .eip20(address: "0xdAC17F958D2ee523a2206206994597C13D831ec7"))))
        #expect(accountType.supports(token: token(code: "USDC", blockchainType: .ethereum, tokenType: .eip20(address: "0xA0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"))))
        #expect(accountType.supports(token: token(code: "DAI", blockchainType: .ethereum, tokenType: .eip20(address: "0x6B175474E89094C44Da98b954EedeAC495271d0F"))))
        #expect(accountType.supports(token: token(code: "USDT", blockchainType: .binanceSmartChain, tokenType: .eip20(address: "0x55d398326f99059fF775485246999027B3197955"))))
        #expect(accountType.supports(token: token(code: "USDC", blockchainType: .base, tokenType: .eip20(address: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913"))))
        #expect(accountType.supports(token: token(code: "USDT", blockchainType: .base, tokenType: .eip20(address: "0xfde4C96c8593536E31F229Ea8f37b2ADa2699bb2"))))
        #expect(accountType.supports(token: token(code: "DAI", blockchainType: .base, tokenType: .eip20(address: "0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb"))))

        #expect(accountType.supports(token: token(code: "ETH", blockchainType: .ethereum, tokenType: .native)) == false)
        #expect(accountType.supports(token: token(code: "BNB", blockchainType: .binanceSmartChain, tokenType: .native)) == false)
        #expect(accountType.supports(token: token(code: "MATIC", blockchainType: .polygon, tokenType: .native)) == false)
        #expect(accountType.supports(token: token(code: "WETH", blockchainType: .ethereum, tokenType: .eip20(address: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"))) == false)
    }

    @Test
    func exposesPasskeySpecificFlags() {
        let accountType = AccountType.passkeyOwned(
            credentialID: Data([0x01, 0x02, 0x03])
        )

        #expect(accountType.mnemonicSeed == nil)
        #expect(accountType.canAddTokens == false)
        #expect(accountType.supportsWalletConnect == false)
        #expect(accountType.supportsTonConnect == false)
        #expect(accountType.watchAddress == nil)
        #expect(accountType.sign(message: Data([0x01])) == nil)
        #expect(accountType.description == "Smart Wallet")
        #expect(accountType.statDescription == "passkey_owned")
    }

    @Test
    func accountStorageRoundTripsPasskeyOwned() throws {
        let environment = try StorageTestEnvironment()
        let account = Account(
            id: UUID().uuidString,
            level: 3,
            name: "Passkey Wallet",
            type: .passkeyOwned(
                credentialID: Data([0x01, 0x02, 0x03, 0x04])
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
    let keychainStorage: KeychainStorage
    let recordStorage: AccountRecordStorage

    init() throws {
        let logger = Logger(minLogLevel: .error)
        keychainStorage = KeychainStorage(service: "account-storage-tests-\(UUID().uuidString)", logger: logger)
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

        recordStorage = AccountRecordStorage(dbPool: dbPool)
        accountStorage = AccountStorage(keychainStorage: keychainStorage, storage: recordStorage)
    }
}
