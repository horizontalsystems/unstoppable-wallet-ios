import RxSwift
import GRDB
import RxGRDB
import KeychainAccess

class GrdbStorage {
    private let dbPool: DatabasePool

    init() {
        let databaseURL = try! FileManager.default
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("bank.sqlite")

        dbPool = try! DatabasePool(path: databaseURL.path)

        try! migrator.migrate(dbPool)
    }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("createAccountRecordsTable") { db in
            try db.create(table: AccountRecord.databaseTableName) { t in
                t.column(AccountRecord.Columns.id.name, .text).notNull()
                t.column(AccountRecord.Columns.name.name, .text).notNull()
                t.column(AccountRecord.Columns.type.name, .text).notNull()
                t.column(AccountRecord.Columns.origin.name, .text).notNull()
                t.column(AccountRecord.Columns.backedUp.name, .boolean).notNull()
                t.column(AccountRecord.Columns.wordsKey.name, .text)
                t.column(AccountRecord.Columns.saltKey.name, .text)
                t.column(AccountRecord.Columns.dataKey.name, .text)
                t.column(AccountRecord.Columns.eosAccount.name, .text)

                t.primaryKey([
                    AccountRecord.Columns.id.name
                ], onConflict: .replace)
            }
        }

        migrator.registerMigration("createEnabledWalletsTable") { db in
            try db.create(table: EnabledWallet.databaseTableName) { t in
                t.column("coinCode", .text).notNull()
                t.column(EnabledWallet.Columns.accountId.name, .text).notNull()
                t.column(EnabledWallet.Columns.syncMode.name, .text)

                t.primaryKey(["coinCode", EnabledWallet.Columns.accountId.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("migrateAuthData") { db in
            let keychain = Keychain(service: "io.horizontalsystems.bank.dev")
            guard let data = try? keychain.getData("auth_data_keychain_key"), let authData = NSKeyedUnarchiver.unarchiveObject(with: data) as? AuthData else {
                return
            }
            try? keychain.remove("auth_data_keychain_key")

            let uuid = authData.walletId
            let isBackedUp = UserDefaults.standard.bool(forKey: "is_backed_up")
            let syncMode: SyncMode
            switch UserDefaults.standard.string(forKey: "sync_mode_key") ?? "" {
            case "fast": syncMode = .fast
            case "slow": syncMode = .slow
            case "new": syncMode = .new
            default: syncMode = .fast
            }

            let wordsKey = "mnemonic_\(uuid)_words"
            let accountRecord = AccountRecord(id: uuid, name: uuid, type: "mnemonic", origin: "restored", backedUp: isBackedUp, wordsKey: wordsKey, saltKey: nil, dataKey: nil, eosAccount: nil)
            try accountRecord.insert(db)

            try? keychain.set(authData.words.joined(separator: ","), key: wordsKey)

            guard try db.tableExists("enabled_coins") else {
                return
            }

            let accountId = accountRecord.id
            try db.execute(sql: """
                                INSERT INTO \(EnabledWallet.databaseTableName)(`coinCode`, `\(EnabledWallet.Columns.accountId.name)`, `\(EnabledWallet.Columns.syncMode.name)`, `walletOrder`)
                                SELECT `coinCode`, '\(accountId)', '\(syncMode)', `coinOrder` FROM enabled_coins
                                """)
            try db.drop(table: "enabled_coins")
        }

        migrator.registerMigration("createPriceAlertRecordsTable") { db in
            try db.create(table: PriceAlertRecord.databaseTableName) { t in
                t.column(PriceAlertRecord.Columns.coinCode.name, .text).notNull()
                t.column(PriceAlertRecord.Columns.state.name, .integer).notNull()
                t.column(PriceAlertRecord.Columns.lastRate.name, .text)

                t.primaryKey([PriceAlertRecord.Columns.coinCode.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("renameCoinCodeToCoinIdInEnabledWallets") { db in
            let tempTableName = "enabled_wallets_temp"

            try db.create(table: tempTableName) { t in
                t.column(EnabledWallet.Columns.coinId.name, .text).notNull()
                t.column(EnabledWallet.Columns.accountId.name, .text).notNull()
                t.column(EnabledWallet.Columns.derivation.name, .text)
                t.column(EnabledWallet.Columns.syncMode.name, .text)

                t.primaryKey([EnabledWallet.Columns.coinId.name, EnabledWallet.Columns.accountId.name], onConflict: .replace)
            }

            try db.execute(sql: """
                                INSERT INTO \(tempTableName)(`\(EnabledWallet.Columns.coinId.name)`, `\(EnabledWallet.Columns.accountId.name)`, `\(EnabledWallet.Columns.syncMode.name)`)
                                SELECT `coinCode`, `accountId`, `syncMode` FROM \(EnabledWallet.databaseTableName)
                                """)

            try db.drop(table: EnabledWallet.databaseTableName)
            try db.rename(table: tempTableName, to: EnabledWallet.databaseTableName)
        }

        return migrator
    }

}

extension GrdbStorage: IEnabledWalletStorage {

    var enabledWallets: [EnabledWallet] {
        try! dbPool.read { db in
            try EnabledWallet.fetchAll(db)
        }
    }

    func save(enabledWallets: [EnabledWallet]) {
        _ = try! dbPool.write { db in
            for enabledWallet in enabledWallets {
                try enabledWallet.insert(db)
            }
        }
    }

    func delete(enabledWallets: [EnabledWallet]) {
        _ = try! dbPool.write { db in
            for enabledWallet in enabledWallets {
                try EnabledWallet.filter(EnabledWallet.Columns.coinId == enabledWallet.coinId && EnabledWallet.Columns.accountId == enabledWallet.accountId).deleteAll(db)
            }
        }
    }

    func clearEnabledWallets() {
        _ = try! dbPool.write { db in
            try EnabledWallet.deleteAll(db)
        }
    }

}

extension GrdbStorage: IAccountRecordStorage {

    var allAccountRecords: [AccountRecord] {
        return try! dbPool.read { db in
            try AccountRecord.fetchAll(db)
        }
    }

    func save(accountRecord: AccountRecord) {
        _ = try! dbPool.write { db in
            try accountRecord.insert(db)
        }
    }

    func deleteAccountRecord(by id: String) {
        _ = try! dbPool.write { db in
            try AccountRecord.filter(AccountRecord.Columns.id == id).deleteAll(db)
        }
    }

    func deleteAllAccountRecords() {
        _ = try! dbPool.write { db in
            try AccountRecord.deleteAll(db)
        }
    }

}

extension GrdbStorage: IPriceAlertRecordStorage {

    var priceAlertRecords: [PriceAlertRecord] {
        try! dbPool.read { db in
            try PriceAlertRecord.fetchAll(db)
        }
    }

    func save(priceAlertRecords: [PriceAlertRecord]) {
        _ = try! dbPool.write { db in
            for record in priceAlertRecords {
                try record.insert(db)
            }
        }
    }

    func deletePriceAlertRecords(coinCodes: [CoinCode]) {
        _ = try! dbPool.write { db in
            try PriceAlertRecord.filter(coinCodes.contains(PriceAlertRecord.Columns.coinCode)).deleteAll(db)
        }
    }

    func deletePriceAlertsExcluding(coinCodes: [CoinCode]) {
        _ = try! dbPool.write { db in
            try PriceAlertRecord.filter(!coinCodes.contains(PriceAlertRecord.Columns.coinCode)).deleteAll(db)
        }
    }

}
