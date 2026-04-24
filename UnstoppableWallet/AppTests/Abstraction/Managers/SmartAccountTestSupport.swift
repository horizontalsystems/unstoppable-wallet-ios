import Foundation
import GRDB
import HsToolKit
@testable import Unstoppable

struct SmartAccountTestEnvironment {
    let tempDir: URL
    let accountManager: AccountManager
    let smartAccountManager: SmartAccountManager

    init() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("sam-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // Build real AccountManager chain with unique keychain service + in-temp DB.
        let bankPool = try DatabasePool(path: tempDir.appendingPathComponent("bank.sqlite").path)
        try bankPool.write { db in
            try db.create(table: AccountRecord.databaseTableName) { t in
                t.column(AccountRecord.Columns.id.rawValue, .text).notNull().primaryKey()
                t.column(AccountRecord.Columns.level.rawValue, .integer).notNull()
                t.column(AccountRecord.Columns.name.rawValue, .text).notNull()
                t.column(AccountRecord.Columns.type.rawValue, .text).notNull()
                t.column(AccountRecord.Columns.origin.rawValue, .text).notNull()
                t.column(AccountRecord.Columns.backedUp.rawValue, .boolean).notNull()
                t.column(AccountRecord.Columns.fileBackedUp.rawValue, .boolean).notNull()
                t.column(AccountRecord.Columns.wordsKey.rawValue, .text)
                t.column(AccountRecord.Columns.saltKey.rawValue, .text)
                t.column(AccountRecord.Columns.dataKey.rawValue, .text)
                t.column(AccountRecord.Columns.bip39Compliant.rawValue, .boolean)
            }
            try db.create(table: ActiveAccount.databaseTableName) { t in
                t.column(ActiveAccount.Columns.level.rawValue, .integer).notNull().primaryKey()
                t.column(ActiveAccount.Columns.accountId.rawValue, .text).notNull()
            }
        }

        let logger = Logger(minLogLevel: .error)
        let keychainStorage = KeychainStorage(service: "sam-tests-\(UUID().uuidString)", logger: logger)
        let accountRecordStorage = AccountRecordStorage(dbPool: bankPool)
        let accountStorage = AccountStorage(keychainStorage: keychainStorage, storage: accountRecordStorage)
        let activeAccountStorage = ActiveAccountStorage(dbPool: bankPool)
        let biometryManager = BiometryManager(userDefaultsStorage: UserDefaultsStorage())
        let passcodeManager = PasscodeManager(biometryManager: biometryManager, keychainStorage: keychainStorage)

        accountManager = AccountManager(
            passcodeManager: passcodeManager,
            accountStorage: accountStorage,
            activeAccountStorage: activeAccountStorage
        )

        smartAccountManager = try SmartAccountManager(
            accountManager: accountManager,
            databaseDirectoryUrl: tempDir
        )
    }

    func makePasskeyAccount(
        id: String = UUID().uuidString,
        name: String = "test",
        credentialID: Data = Data(repeating: 0xCC, count: 16),
        publicKeyX: Data = Data(repeating: 0x11, count: 32),
        publicKeyY: Data = Data(repeating: 0x22, count: 32)
    ) -> Account {
        Account(
            id: id,
            level: 0,
            name: name,
            type: .passkeyOwned(credentialID: credentialID, publicKeyX: publicKeyX, publicKeyY: publicKeyY),
            origin: .created,
            backedUp: true,
            fileBackedUp: false
        )
    }
}
