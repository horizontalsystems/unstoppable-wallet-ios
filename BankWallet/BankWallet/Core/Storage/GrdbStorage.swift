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

        migrator.registerMigration("createRate") { db in
            try db.create(table: Rate.databaseTableName) { t in
                t.column(Rate.Columns.coinCode.name, .text).notNull()
                t.column(Rate.Columns.currencyCode.name, .text).notNull()
                t.column(Rate.Columns.value.name, .text).notNull()
                t.column(Rate.Columns.isLatest.name, .boolean).notNull()

                t.primaryKey([
                    Rate.Columns.coinCode.name,
                    Rate.Columns.currencyCode.name,
                    Rate.Columns.isLatest.name
                ], onConflict: .replace)
            }
        }

        migrator.registerMigration("createAccountRecordsTable") { db in
            try db.create(table: AccountRecord.databaseTableName) { t in
                t.column(AccountRecord.Columns.id.name, .text).notNull()
                t.column(AccountRecord.Columns.name.name, .text).notNull()
                t.column(AccountRecord.Columns.type.name, .integer).notNull()
                t.column(AccountRecord.Columns.backedUp.name, .boolean).notNull()
                t.column(AccountRecord.Columns.defaultSyncMode.name, .text)
                t.column(AccountRecord.Columns.wordsKey.name, .text)
                t.column(AccountRecord.Columns.derivation.name, .integer)
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
                t.column(EnabledWallet.Columns.coinCode.name, .text).notNull()
                t.column(EnabledWallet.Columns.accountId.name, .text).notNull()
                t.column(EnabledWallet.Columns.syncMode.name, .text)
                t.column(EnabledWallet.Columns.walletOrder.name, .integer).notNull()

                t.primaryKey([EnabledWallet.Columns.coinCode.name, EnabledWallet.Columns.accountId.name], onConflict: .replace)
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
            let accountRecord = AccountRecord(id: uuid, name: uuid, type: "mnemonic", backedUp: isBackedUp, defaultSyncMode: syncMode.rawValue, wordsKey: wordsKey, derivation: "bip44", saltKey: nil, dataKey: nil, eosAccount: nil)
            try accountRecord.insert(db)

            try? keychain.set(authData.words.joined(separator: ","), key: wordsKey)

            guard try db.tableExists("enabled_coins") else {
                return
            }

            let accountId = accountRecord.id
            try db.execute(sql: """
                                INSERT INTO \(EnabledWallet.databaseTableName)(`\(EnabledWallet.Columns.coinCode.name)`, `\(EnabledWallet.Columns.accountId.name)`, `\(EnabledWallet.Columns.syncMode.name)`, `\(EnabledWallet.Columns.walletOrder.name)`)
                                SELECT `coinCode`, '\(accountId)', '\(syncMode)', `coinOrder` FROM enabled_coins
                                """)
            try db.drop(table: "enabled_coins")
        }

        migrator.registerMigration("timestampToDateRates") { db in
            try db.drop(table: Rate.databaseTableName)
            try db.create(table: Rate.databaseTableName) { t in
                t.column(Rate.Columns.coinCode.name, .text).notNull()
                t.column(Rate.Columns.currencyCode.name, .text).notNull()
                t.column(Rate.Columns.value.name, .text).notNull()
                t.column(Rate.Columns.date.name, .double).notNull()
                t.column(Rate.Columns.isLatest.name, .boolean).notNull()

                t.primaryKey([
                    Rate.Columns.coinCode.name,
                    Rate.Columns.currencyCode.name,
                    Rate.Columns.date.name,
                    Rate.Columns.isLatest.name
                ], onConflict: .replace)
            }
        }

        migrator.registerMigration("createPriceAlertRecordsTable") { db in
            try db.create(table: PriceAlertRecord.databaseTableName) { t in
                t.column(PriceAlertRecord.Columns.coinCode.name, .text).notNull()
                t.column(PriceAlertRecord.Columns.state.name, .integer).notNull()

                t.primaryKey([PriceAlertRecord.Columns.coinCode.name], onConflict: .replace)
            }
        }

        return migrator
    }

}

extension GrdbStorage: IRateStorage {

    func latestRate(coinCode: CoinCode, currencyCode: String) -> Rate? {
        return try! dbPool.read { db in
            let request = Rate.filter(Rate.Columns.coinCode == coinCode && Rate.Columns.currencyCode == currencyCode && Rate.Columns.isLatest == true)
            return try request.fetchOne(db)
        }
    }

    func latestRateObservable(forCoinCode coinCode: CoinCode, currencyCode: String) -> Observable<Rate> {
        let request = Rate.filter(Rate.Columns.coinCode == coinCode && Rate.Columns.currencyCode == currencyCode && Rate.Columns.isLatest == true)
        return request.rx.observeFirst(in: dbPool)
                .flatMap { $0.map(Observable.just) ?? Observable.empty() }
    }

    func timestampRateObservable(coinCode: CoinCode, currencyCode: String, date: Date) -> Observable<Rate?> {
        let request = Rate.filter(Rate.Columns.coinCode == coinCode && Rate.Columns.currencyCode == currencyCode && Rate.Columns.date == date && Rate.Columns.isLatest == false)
        return request.rx.observeFirst(in: dbPool)
    }

    func zeroValueTimestampRatesObservable(currencyCode: String) -> Observable<[Rate]> {
        let request = Rate.filter(Rate.Columns.currencyCode == currencyCode && Rate.Columns.value == 0 && Rate.Columns.isLatest == false)
        return request.rx.observeAll(in: dbPool)
    }

    func save(latestRate: Rate) {
        _ = try? dbPool.write { db in
            try Rate.filter(Rate.Columns.coinCode == latestRate.coinCode && Rate.Columns.currencyCode == latestRate.currencyCode && Rate.Columns.isLatest == true).deleteAll(db)
            try latestRate.insert(db)
        }
    }

    func save(rate: Rate) {
        _ = try? dbPool.write { db in
            try rate.insert(db)
        }
    }

    func clearRates() {
        _ = try? dbPool.write { db in
            try Rate.deleteAll(db)
        }
    }

}

extension GrdbStorage: IEnabledWalletStorage {

    var enabledWallets: [EnabledWallet] {
        return try! dbPool.read { db in
            try EnabledWallet.order(EnabledWallet.Columns.walletOrder).fetchAll(db)
        }
    }

    func save(enabledWallets: [EnabledWallet]) {
        _ = try! dbPool.write { db in
            try EnabledWallet.deleteAll(db)

            for enabledWallet in enabledWallets {
                try enabledWallet.insert(db)
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
        return try! dbPool.read { db in
            try PriceAlertRecord.fetchAll(db)
        }
    }

    var priceAlertRecordCount: Int {
        return try! dbPool.read { db in
            try PriceAlertRecord.fetchAll(db).count
        }
    }

    func save(priceAlertRecord: PriceAlertRecord) {
        _ = try! dbPool.write { db in
            try priceAlertRecord.insert(db)
        }
    }

    func deletePriceAlertRecord(coinCode: CoinCode) {
        _ = try! dbPool.write { db in
            try PriceAlertRecord.filter(PriceAlertRecord.Columns.coinCode == coinCode).deleteAll(db)
        }
    }

    func deletePriceAlertsExcluding(coinCodes: [CoinCode]) {
        _ = try! dbPool.write { db in
            try PriceAlertRecord.filter(!coinCodes.contains(PriceAlertRecord.Columns.coinCode)).deleteAll(db)
        }
    }

}
