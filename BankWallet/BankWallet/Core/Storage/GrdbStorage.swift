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
            try db.create(table: AccountRecord_v_0_10.databaseTableName) { t in
                t.column(AccountRecord_v_0_10.Columns.id.name, .text).notNull()
                t.column(AccountRecord_v_0_10.Columns.name.name, .text).notNull()
                t.column(AccountRecord_v_0_10.Columns.type.name, .integer).notNull()
                t.column(AccountRecord_v_0_10.Columns.backedUp.name, .boolean).notNull()
                t.column(AccountRecord_v_0_10.Columns.defaultSyncMode.name, .text)
                t.column(AccountRecord_v_0_10.Columns.wordsKey.name, .text)
                t.column(AccountRecord_v_0_10.Columns.derivation.name, .integer)
                t.column(AccountRecord_v_0_10.Columns.saltKey.name, .text)
                t.column(AccountRecord_v_0_10.Columns.dataKey.name, .text)
                t.column(AccountRecord_v_0_10.Columns.eosAccount.name, .text)

                t.primaryKey([
                    AccountRecord_v_0_10.Columns.id.name
                ], onConflict: .replace)
            }
        }

        migrator.registerMigration("createEnabledWalletsTable") { db in
            try db.create(table: EnabledWallet_v_0_10.databaseTableName) { t in
                t.column("coinCode", .text).notNull()
                t.column(EnabledWallet_v_0_10.Columns.accountId.name, .text).notNull()
                t.column(EnabledWallet_v_0_10.Columns.syncMode.name, .text)
                t.column(EnabledWallet_v_0_10.Columns.walletOrder.name, .integer).notNull()

                t.primaryKey(["coinCode", EnabledWallet.Columns.accountId.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("migrateAuthData") { db in
            let keychain = Keychain(service: "io.horizontalsystems.bank.dev")
            guard let data = try? keychain.getData("auth_data_keychain_key"), let authData = try? NSKeyedUnarchiver.unarchivedObject(ofClass: AuthData.self, from: data) else {
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

            let accountRecord = AccountRecord_v_0_10(id: uuid, name: uuid, type: "mnemonic", backedUp: isBackedUp, defaultSyncMode: syncMode.rawValue, wordsKey: wordsKey, derivation: "bip44", saltKey: nil, dataKey: nil, eosAccount: nil)
            try accountRecord.insert(db)

            try? keychain.set(authData.words.joined(separator: ","), key: wordsKey)

            guard try db.tableExists("enabled_coins") else {
                return
            }

            let accountId = accountRecord.id
            try db.execute(sql: """
                                INSERT INTO \(EnabledWallet_v_0_10.databaseTableName)(`coinCode`, `\(EnabledWallet_v_0_10.Columns.accountId.name)`, `\(EnabledWallet_v_0_10.Columns.syncMode.name)`, `\(EnabledWallet_v_0_10.Columns.walletOrder.name)`)
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
                t.column(EnabledWallet_v_0_10.Columns.coinId.name, .text).notNull()
                t.column(EnabledWallet_v_0_10.Columns.accountId.name, .text).notNull()
                t.column(EnabledWallet_v_0_10.Columns.syncMode.name, .text)
                t.column(EnabledWallet_v_0_10.Columns.walletOrder.name, .integer).notNull()

                t.primaryKey([EnabledWallet_v_0_10.Columns.coinId.name, EnabledWallet_v_0_10.Columns.accountId.name], onConflict: .replace)
            }

            try db.execute(sql: """
                                INSERT INTO \(tempTableName)(`\(EnabledWallet_v_0_10.Columns.coinId.name)`, `\(EnabledWallet_v_0_10.Columns.accountId.name)`, `\(EnabledWallet_v_0_10.Columns.syncMode.name)`, `\(EnabledWallet_v_0_10.Columns.walletOrder.name)`)
                                SELECT `coinCode`, `accountId`, `syncMode`, `walletOrder` FROM \(EnabledWallet_v_0_10.databaseTableName)
                                """)

            try db.drop(table: EnabledWallet_v_0_10.databaseTableName)
            try db.rename(table: tempTableName, to: EnabledWallet_v_0_10.databaseTableName)
        }

        migrator.registerMigration("moveCoinSettingsFromAccountToWallet") { db in
            var oldDerivation: String?
            var oldSyncMode: String?

            let oldAccounts = try AccountRecord_v_0_10.fetchAll(db)

            try db.drop(table: AccountRecord_v_0_10.databaseTableName)

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

                t.primaryKey([AccountRecord.Columns.id.name], onConflict: .replace)
            }

            for oldAccount in oldAccounts {
                let origin = oldAccount.defaultSyncMode == "new" ? "created" : "restored"

                let newAccount = AccountRecord(
                        id: oldAccount.id,
                        name: oldAccount.name,
                        type: oldAccount.type,
                        origin: origin,
                        backedUp: oldAccount.backedUp,
                        wordsKey: oldAccount.wordsKey,
                        saltKey: oldAccount.saltKey,
                        dataKey: oldAccount.dataKey,
                        eosAccount: oldAccount.eosAccount
                )

                try newAccount.insert(db)

                if let defaultSyncMode = oldAccount.defaultSyncMode, let derivation = oldAccount.derivation {
                    oldDerivation = derivation
                    oldSyncMode = defaultSyncMode
                }
            }

            let oldWallets = try EnabledWallet_v_0_10.fetchAll(db)

            try db.drop(table: EnabledWallet_v_0_10.databaseTableName)

            try db.create(table: EnabledWallet.databaseTableName) { t in
                t.column(EnabledWallet.Columns.coinId.name, .text).notNull()
                t.column(EnabledWallet.Columns.accountId.name, .text).notNull()
                t.column(EnabledWallet.Columns.derivation.name, .text)
                t.column(EnabledWallet.Columns.syncMode.name, .text)

                t.primaryKey([EnabledWallet.Columns.coinId.name, EnabledWallet.Columns.accountId.name], onConflict: .replace)
            }

            for oldWallet in oldWallets {
                var derivation: String?
                var syncMode: String?

                if let oldDerivation = oldDerivation, oldWallet.coinId == "BTC" {
                    derivation = oldDerivation
                }

                if let oldSyncMode = oldSyncMode, (oldWallet.coinId == "BTC" || oldWallet.coinId == "BCH" || oldWallet.coinId == "DASH") {
                    syncMode = oldSyncMode
                }

                let newWallet = EnabledWallet(
                        coinId: oldWallet.coinId,
                        accountId: oldWallet.accountId,
                        derivation: derivation,
                        syncMode: syncMode
                )

                try newWallet.insert(db)
            }
        }

        migrator.registerMigration("renameDaiCoinToSai") { db in
            guard let wallet = try EnabledWallet.filter(EnabledWallet.Columns.coinId == "DAI").fetchOne(db) else {
                return
            }

            let newWallet = EnabledWallet(
                    coinId: "SAI",
                    accountId: wallet.accountId,
                    derivation: wallet.derivation,
                    syncMode: wallet.syncMode
            )

            try wallet.delete(db)
            try newWallet.save(db)
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
