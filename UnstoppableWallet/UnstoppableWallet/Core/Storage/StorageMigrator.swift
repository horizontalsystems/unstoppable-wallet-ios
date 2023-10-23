import Foundation
import RxSwift
import RxCocoa
import GRDB
import KeychainAccess
import HsToolKit
import MarketKit

class StorageMigrator {

    static func migrate(dbPool: DatabasePool) throws {
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

                t.primaryKey(["coinCode", EnabledWallet_v_0_10.Columns.accountId.name], onConflict: .replace)
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
            let syncMode: SyncMode_v_0_24
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

            try db.create(table: AccountRecord_v_0_19.databaseTableName) { t in
                t.column(AccountRecord_v_0_19.Columns.id.name, .text).notNull()
                t.column(AccountRecord_v_0_19.Columns.name.name, .text).notNull()
                t.column(AccountRecord_v_0_19.Columns.type.name, .text).notNull()
                t.column(AccountRecord_v_0_19.Columns.origin.name, .text).notNull()
                t.column(AccountRecord_v_0_19.Columns.backedUp.name, .boolean).notNull()
                t.column(AccountRecord_v_0_19.Columns.wordsKey.name, .text)
                t.column(AccountRecord_v_0_19.Columns.saltKey.name, .text)
                t.column(AccountRecord_v_0_19.Columns.dataKey.name, .text)
                t.column(AccountRecord_v_0_19.Columns.eosAccount.name, .text)

                t.primaryKey([AccountRecord_v_0_19.Columns.id.name], onConflict: .replace)
            }

            for oldAccount in oldAccounts {
                let origin = oldAccount.defaultSyncMode == "new" ? "created" : "restored"

                let newAccount = AccountRecord_v_0_19(
                        id: oldAccount.id,
                        name: oldAccount.name,
                        type: oldAccount.type,
                        origin: origin,
                        backedUp: oldAccount.backedUp,
                        wordsKey: oldAccount.wordsKey,
                        saltKey: oldAccount.saltKey,
                        birthdayHeightKey: nil,
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

            try db.create(table: EnabledWallet_v_0_13.databaseTableName) { t in
                t.column(EnabledWallet_v_0_13.Columns.coinId.name, .text).notNull()
                t.column(EnabledWallet_v_0_13.Columns.accountId.name, .text).notNull()
                t.column(EnabledWallet_v_0_13.Columns.derivation.name, .text)
                t.column(EnabledWallet_v_0_13.Columns.syncMode.name, .text)

                t.primaryKey([EnabledWallet_v_0_13.Columns.coinId.name, EnabledWallet_v_0_13.Columns.accountId.name], onConflict: .replace)
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

                let newWallet = EnabledWallet_v_0_13(
                        coinId: oldWallet.coinId,
                        accountId: oldWallet.accountId,
                        derivation: derivation,
                        syncMode: syncMode
                )

                try newWallet.insert(db)
            }
        }

        migrator.registerMigration("renameDaiCoinToSai") { db in
            guard let wallet = try EnabledWallet_v_0_13.filter(EnabledWallet_v_0_13.Columns.coinId == "DAI").fetchOne(db) else {
                return
            }

            let newWallet = EnabledWallet_v_0_13(
                    coinId: "SAI",
                    accountId: wallet.accountId,
                    derivation: wallet.derivation,
                    syncMode: wallet.syncMode
            )

            try wallet.delete(db)
            try newWallet.save(db)
        }

        migrator.registerMigration("createBlockchainSettings") { db in
            try db.create(table: BlockchainSettingRecord_v_0_24.databaseTableName) { t in
                t.column(BlockchainSettingRecord_v_0_24.Columns.coinType.name, .text).notNull()
                t.column(BlockchainSettingRecord_v_0_24.Columns.key.name, .text).notNull()
                t.column(BlockchainSettingRecord_v_0_24.Columns.value.name, .text).notNull()

                t.primaryKey([BlockchainSettingRecord_v_0_24.Columns.coinType.name, BlockchainSettingRecord_v_0_24.Columns.key.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("fillBlockchainSettingsFromEnabledWallets") { db in
            let wallets = try EnabledWallet_v_0_13.filter(EnabledWallet_v_0_13.Columns.coinId == "BTC" ||
                    EnabledWallet_v_0_13.Columns.coinId == "LTC" ||
                    EnabledWallet_v_0_13.Columns.coinId == "BCH" ||
                    EnabledWallet_v_0_13.Columns.coinId == "DASH").fetchAll(db)

            let coinTypeKeyMap = [
                "BTC": "bitcoin",
                "LTC": "litecoin",
                "BCH": "bitcoinCash",
                "DASH": "dash"
            ]

            let derivationSettings: [BlockchainSettingRecord_v_0_24] = wallets.compactMap { wallet in
                guard
                        let coinTypeKey = coinTypeKeyMap[wallet.coinId],
                        let derivation = wallet.derivation
                        else {
                    return nil
                }

                return BlockchainSettingRecord_v_0_24(coinType: coinTypeKey, key: "derivation", value: derivation)
            }
            let syncSettings: [BlockchainSettingRecord_v_0_24] = wallets.compactMap { wallet in
                guard
                        let coinTypeKey = coinTypeKeyMap[wallet.coinId],
                        let syncMode = wallet.syncMode
                        else {
                    return nil
                }

                return BlockchainSettingRecord_v_0_24(coinType: coinTypeKey, key: "sync_mode", value: syncMode)
            }

            for setting in derivationSettings + syncSettings {
                try setting.insert(db)
            }
        }

        migrator.registerMigration("createCoins") { db in
            try db.create(table: CoinRecord_v19.databaseTableName) { t in
                t.column(CoinRecord_v19.Columns.coinId.name, .text).notNull()
                t.column(CoinRecord_v19.Columns.title.name, .text).notNull()
                t.column(CoinRecord_v19.Columns.code.name, .text).notNull()
                t.column(CoinRecord_v19.Columns.decimal.name, .integer).notNull()
                t.column(CoinRecord_v19.Columns.tokenType.name, .text).notNull()
                t.column(CoinRecord_v19.Columns.erc20Address.name, .text)

                t.primaryKey([CoinRecord_v19.Columns.coinId.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("createLogs") { db in
            try db.create(table: LogRecord.databaseTableName) { t in
                t.column(LogRecord.Columns.date.name, .double).notNull()
                t.column(LogRecord.Columns.level.name, .integer).notNull()
                t.column(LogRecord.Columns.context.name, .text).notNull()
                t.column(LogRecord.Columns.message.name, .text).notNull()
            }
        }

        migrator.registerMigration("addBirthdayHeightToAccountRecord") { db in
            try db.alter(table: AccountRecord_v_0_19.databaseTableName) { t in
                t.add(column: AccountRecord_v_0_19.Columns.birthdayHeightKey.name, .text)
            }
        }

        migrator.registerMigration("addBep2SymbolToCoins") { db in
            try db.alter(table: CoinRecord_v19.databaseTableName) { t in
                t.add(column: CoinRecord_v19.Columns.bep2Symbol.name, .text)
            }
        }

        migrator.registerMigration("addCoinTypeBlockchainSettingForBitcoinCash") { db in
            if try EnabledWallet_v_0_20.filter(EnabledWallet_v_0_20.Columns.coinId == "BCH").fetchOne(db) != nil {
                let record = BlockchainSettingRecord_v_0_24(coinType: "bitcoinCash", key: "network_coin_type", value: "type0")
                try record.insert(db)
            }
        }

        migrator.registerMigration("deleteEosAccountFromAccountRecordAndRemoveEosAccountAndWallets") { db in
            let oldAccounts = try AccountRecord_v_0_19.fetchAll(db)

            try db.drop(table: AccountRecord_v_0_19.databaseTableName)

            try db.create(table: AccountRecord_v_0_20.databaseTableName) { t in
                t.column(AccountRecord_v_0_20.Columns.id.name, .text).notNull()
                t.column(AccountRecord_v_0_20.Columns.name.name, .text).notNull()
                t.column(AccountRecord_v_0_20.Columns.type.name, .text).notNull()
                t.column(AccountRecord_v_0_20.Columns.origin.name, .text).notNull()
                t.column(AccountRecord_v_0_20.Columns.backedUp.name, .boolean).notNull()
                t.column(AccountRecord_v_0_20.Columns.wordsKey.name, .text)
                t.column(AccountRecord_v_0_20.Columns.saltKey.name, .text)
                t.column(AccountRecord_v_0_20.Columns.birthdayHeightKey.name, .text)
                t.column(AccountRecord_v_0_20.Columns.dataKey.name, .text)

                t.primaryKey([AccountRecord_v_0_20.Columns.id.name], onConflict: .replace)
            }

            for oldAccount in oldAccounts {
                if oldAccount.type == "eos" {
                    try EnabledWallet_v_0_20.filter(EnabledWallet_v_0_20.Columns.accountId == oldAccount.id).deleteAll(db)
                    continue
                }

                let newAccount = AccountRecord_v_0_20(
                        id: oldAccount.id,
                        name: oldAccount.name,
                        type: oldAccount.type,
                        origin: oldAccount.origin,
                        backedUp: oldAccount.backedUp,
                        wordsKey: oldAccount.wordsKey,
                        saltKey: oldAccount.saltKey,
                        birthdayHeightKey: oldAccount.birthdayHeightKey,
                        dataKey: oldAccount.dataKey
                )

                try newAccount.insert(db)
            }
        }

        migrator.registerMigration("extractCoinsAndChangeCoinIds") { db in
            // apply changes in database
            try db.drop(table: CoinRecord_v19.databaseTableName)
        }

        migrator.registerMigration("recreateFavoriteCoins") { db in
            if try db.tableExists("favorite_coins") {
                try db.drop(table: "favorite_coins")
            }

            try db.create(table: "favorite_coins_v20") { t in
                t.column("coinType", .text).notNull()
            }
        }

        migrator.registerMigration("createActiveAccount") { db in
            try db.create(table: ActiveAccount_v_0_36.databaseTableName) { t in
                t.column(ActiveAccount_v_0_36.Columns.uniqueId.name, .text).notNull()
                t.column(ActiveAccount_v_0_36.Columns.accountId.name, .text).notNull()

                t.primaryKey([ActiveAccount_v_0_36.Columns.uniqueId.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("createRestoreSettings") { db in
            try db.create(table: RestoreSettingRecord_v_0_25.databaseTableName) { t in
                t.column(RestoreSettingRecord_v_0_25.Columns.accountId.name, .text).notNull()
                t.column(RestoreSettingRecord_v_0_25.Columns.coinId.name, .text).notNull()
                t.column(RestoreSettingRecord_v_0_25.Columns.key.name, .text).notNull()
                t.column(RestoreSettingRecord_v_0_25.Columns.value.name, .text)

                t.primaryKey([RestoreSettingRecord_v_0_25.Columns.accountId.name, RestoreSettingRecord_v_0_25.Columns.coinId.name, RestoreSettingRecord_v_0_25.Columns.key.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("moveCoinSettingsFromBlockchainSettingsToWallet") { db in
            let oldAccounts = try AccountRecord_v_0_20.fetchAll(db)

            try db.drop(table: AccountRecord_v_0_20.databaseTableName)

            try db.create(table: AccountRecord_v_0_36.databaseTableName) { t in
                t.column(AccountRecord_v_0_36.Columns.id.name, .text).notNull()
                t.column(AccountRecord_v_0_36.Columns.name.name, .text).notNull()
                t.column(AccountRecord_v_0_36.Columns.type.name, .text).notNull()
                t.column(AccountRecord_v_0_36.Columns.origin.name, .text).notNull()
                t.column(AccountRecord_v_0_36.Columns.backedUp.name, .boolean).notNull()
                t.column(AccountRecord_v_0_36.Columns.wordsKey.name, .text)
                t.column(AccountRecord_v_0_36.Columns.saltKey.name, .text)
                t.column(AccountRecord_v_0_36.Columns.dataKey.name, .text)

                t.primaryKey([AccountRecord_v_0_36.Columns.id.name], onConflict: .replace)
            }

            for (index, oldAccount) in oldAccounts.enumerated() {
                var accountType = oldAccount.type

                if accountType == "zcash" {
                    let keychain = Keychain(service: "io.horizontalsystems.bank.dev")

                    let key = "zcash_\(oldAccount.id)_birthdayHeight"
                    if let birthdayHeightString = keychain[key], let birthdayHeight = Int(birthdayHeightString) {
                        let restoreSetting = RestoreSettingRecord_v_0_25(accountId: oldAccount.id, coinId: "zcash", key: "birthdayHeight", value: String(birthdayHeight))
                        try restoreSetting.insert(db)
                    }
                    try? keychain.remove(key)

                    let oldWordsKey = "zcash_\(oldAccount.id)_words"
                    let newWordsKey = "mnemonic_\(oldAccount.id)_words"
                    if let wordsValue = keychain[oldWordsKey] {
                        try keychain.set(wordsValue, key: newWordsKey)
                    }

                    accountType = "mnemonic"
                }

                let newAccount = AccountRecord_v_0_36(
                        id: oldAccount.id,
                        name: "Wallet \(index + 1)",
                        type: accountType,
                        origin: oldAccount.origin,
                        backedUp: oldAccount.backedUp,
                        wordsKey: oldAccount.wordsKey,
                        saltKey: oldAccount.saltKey,
                        dataKey: oldAccount.dataKey,
                        bip39Compliant: nil
                )

                try newAccount.insert(db)

                if index == 0 {
                    let activeAccount = ActiveAccount_v_0_36(accountId: oldAccount.id)
                    try activeAccount.insert(db)
                }
            }

            let oldWallets = try EnabledWallet_v_0_20.fetchAll(db)

            try db.drop(table: EnabledWallet_v_0_20.databaseTableName)

            try db.create(table: EnabledWallet_v_0_25.databaseTableName) { t in
                t.column(EnabledWallet_v_0_25.Columns.coinId.name, .text).notNull()
                t.column(EnabledWallet_v_0_25.Columns.coinSettingsId.name, .text).notNull()
                t.column(EnabledWallet_v_0_25.Columns.accountId.name, .text).notNull()

                t.primaryKey([EnabledWallet_v_0_25.Columns.coinId.name, EnabledWallet_v_0_25.Columns.coinSettingsId.name, EnabledWallet_v_0_25.Columns.accountId.name], onConflict: .replace)
            }

            let settingRecords = try BlockchainSettingRecord_v_0_24.fetchAll(db)

            for oldWallet in oldWallets {
                let coinId = oldWallet.coinId
                var coinSettingsId = ""

                if coinId == "bitcoin" || coinId == "litecoin" {
                    let oldSetting = settingRecords.first { $0.coinType == coinId && $0.key == "derivation" }
                    let newValue = oldSetting?.value ?? "bip49"
                    coinSettingsId = "derivation:\(newValue)"
                } else if coinId == "bitcoinCash" {
                    let oldSetting = settingRecords.first { $0.coinType == coinId && $0.key == "network_coin_type" }
                    let newValue = oldSetting?.value ?? "type145"
                    coinSettingsId = "bitcoinCashCoinType:\(newValue)"
                }

                let newWallet = EnabledWallet_v_0_25(
                        coinId: oldWallet.coinId,
                        coinSettingsId: coinSettingsId,
                        accountId: oldWallet.accountId
                )

                try newWallet.insert(db)
            }
        }

        migrator.registerMigration("createAppVersionRecordsTable") { db in
            try db.create(table: AppVersionRecord.databaseTableName) { t in
                t.column(AppVersionRecord.Columns.version.name, .text).notNull()
                t.column(AppVersionRecord.Columns.build.name, .text)
                t.column(AppVersionRecord.Columns.date.name, .text).notNull()

                t.primaryKey([AppVersionRecord.Columns.version.name, AppVersionRecord.Columns.build.name], onConflict: .replace)
            }

            guard let data: Data = UserDefaults.standard.value(forKey: "app_versions") as? Data, let oldVersions = try? JSONDecoder().decode([AppVersion_v_0_20].self, from: data) else {
                return
            }

            try oldVersions.forEach { oldVersion in
                let regex = try! NSRegularExpression(pattern: "\\(.*\\)")
                let matches = regex.matches(in: oldVersion.version, range: NSRange(location: 0, length: oldVersion.version.count))

                var build: String?
                var version = oldVersion.version

                if let match = matches.last, let range = Range(match.range, in: oldVersion.version) {
                    build = String(oldVersion.version[range])
                    build?.removeAll { character in character == "(" || character == ")" }

                    version.removeSubrange(range)
                }
                version = version.trimmingCharacters(in: .whitespaces)

                let versionRecord = AppVersionRecord(version: version, build: build, date: oldVersion.date)
                try versionRecord.insert(db)
            }
        }

        migrator.registerMigration("fillSaltToAccountsKeychain") { db in
            let keychain = Keychain(service: "io.horizontalsystems.bank.dev")
            let records = try AccountRecord_v_0_36.fetchAll(db)

            for record in records {
                try keychain.set("", key: "mnemonic_\(record.id)_salt")
            }
        }

        migrator.registerMigration("createCustomTokens") { db in
            try db.create(table: CustomToken.databaseTableName) { t in
                t.column(CustomToken.Columns.coinName.name, .text).notNull()
                t.column(CustomToken.Columns.coinCode.name, .text).notNull()
                t.column(CustomToken.Columns.coinTypeId.name, .text).notNull()
                t.column(CustomToken.Columns.decimals.name, .integer).notNull()

                t.primaryKey([CustomToken.Columns.coinTypeId.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("newStructureForFavoriteCoins") { db in
            try db.create(table: FavoriteCoinRecord.databaseTableName) { t in
                t.column(FavoriteCoinRecord.Columns.coinUid.name, .text).primaryKey()
            }
        }

        migrator.registerMigration("createWalletConnectV2Sessions") { db in
            try db.create(table: WalletConnectSession.databaseTableName) { t in
                t.column(WalletConnectSession.Columns.accountId.name, .text).notNull()
                t.column(WalletConnectSession.Columns.topic.name, .text).notNull()

                t.primaryKey([WalletConnectSession.Columns.accountId.name, WalletConnectSession.Columns.topic.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("migrateBlockchainSettings") { db in
            let oldRecords = try BlockchainSettingRecord_v_0_24.fetchAll(db)

            try db.drop(table: BlockchainSettingRecord_v_0_24.databaseTableName)

            try db.create(table: BlockchainSettingRecord.databaseTableName) { t in
                t.column(BlockchainSettingRecord.Columns.blockchainUid.name, .text).notNull()
                t.column(BlockchainSettingRecord.Columns.key.name, .text).notNull()
                t.column(BlockchainSettingRecord.Columns.value.name, .text).notNull()

                t.primaryKey([BlockchainSettingRecord.Columns.blockchainUid.name, BlockchainSettingRecord.Columns.key.name], onConflict: .replace)
            }

            for oldRecord in oldRecords {
                if oldRecord.key == "initial_sync", oldRecord.value == "slow" {
                    try BlockchainSettingRecord(blockchainUid: oldRecord.coinType, key: "btc-restore", value: "blockchain").insert(db)
                }

                if let sortMode = UserDefaults.standard.string(forKey: "transaction_data_sort_mode"), sortMode == "bip69" {
                    try BlockchainSettingRecord(blockchainUid: "bitcoin", key: "btc-transaction-sort", value: "bip69").insert(db)
                    try BlockchainSettingRecord(blockchainUid: "bitcoinCash", key: "btc-transaction-sort", value: "bip69").insert(db)
                    try BlockchainSettingRecord(blockchainUid: "litecoin", key: "btc-transaction-sort", value: "bip69").insert(db)
                    try BlockchainSettingRecord(blockchainUid: "dash", key: "btc-transaction-sort", value: "bip69").insert(db)
                }
            }
        }

        migrator.registerMigration("migrateCustomTokensToEnabledWallets") { db in
            try db.alter(table: EnabledWallet_v_0_25.databaseTableName) { t in
                t.add(column: EnabledWallet_v_0_25.Columns.coinName.name, .text)
                t.add(column: EnabledWallet_v_0_25.Columns.coinCode.name, .text)
                t.add(column: EnabledWallet_v_0_25.Columns.coinDecimals.name, .integer)
            }

            let customTokens = try CustomToken.fetchAll(db)
            try db.drop(table: CustomToken.databaseTableName)

            for customToken in customTokens {
                if let enabledWallet = try EnabledWallet_v_0_25.filter(EnabledWallet_v_0_25.Columns.coinId == customToken.coinTypeId).fetchOne(db) {
                    let newEnabledWallet = EnabledWallet_v_0_25(
                            coinId: enabledWallet.coinId,
                            coinSettingsId: enabledWallet.coinSettingsId,
                            accountId: enabledWallet.accountId,
                            coinName: customToken.coinName,
                            coinCode: customToken.coinCode,
                            coinDecimals: customToken.decimals
                    )

                    try newEnabledWallet.insert(db)
                }
            }
        }

        migrator.registerMigration("Create SyncerState") { db in
            try db.create(table: SyncerState.databaseTableName) { t in
                t.column(SyncerState.Columns.key.name, .text).notNull().primaryKey(onConflict: .replace)
                t.column(SyncerState.Columns.value.name, .text).notNull()
            }
        }

        migrator.registerMigration("Create EvmMethodLabel") { db in
            try db.create(table: EvmMethodLabel.databaseTableName) { t in
                t.column(EvmMethodLabel.Columns.methodId.name, .text).notNull().primaryKey(onConflict: .replace)
                t.column(EvmMethodLabel.Columns.label.name, .text).notNull()
            }
        }

        migrator.registerMigration("Create EvmAddressLabel") { db in
            try db.create(table: EvmAddressLabel.databaseTableName) { t in
                t.column(EvmAddressLabel.Columns.address.name, .text).notNull().primaryKey(onConflict: .replace)
                t.column(EvmAddressLabel.Columns.label.name, .text).notNull()
            }
        }

        migrator.registerMigration("Migrate refactoring of MarketKit") { db in

            // RestoreSettingRecord

            let oldRestoreSettings = try RestoreSettingRecord_v_0_25.fetchAll(db)

            try db.drop(table: RestoreSettingRecord_v_0_25.databaseTableName)

            try db.create(table: RestoreSettingRecord.databaseTableName) { t in
                t.column(RestoreSettingRecord.Columns.accountId.name, .text).notNull()
                t.column(RestoreSettingRecord.Columns.blockchainUid.name, .text).notNull()
                t.column(RestoreSettingRecord.Columns.key.name, .text).notNull()
                t.column(RestoreSettingRecord.Columns.value.name, .text)

                t.primaryKey([RestoreSettingRecord.Columns.accountId.name, RestoreSettingRecord.Columns.blockchainUid.name, RestoreSettingRecord.Columns.key.name], onConflict: .replace)
            }

            for old in oldRestoreSettings {
                let record = RestoreSettingRecord(
                        accountId: old.accountId,
                        blockchainUid: old.coinId, // old setting used coin type id and for Zcash only. Blockchain uid and coin type id for Zcash is the same
                        key: old.key,
                        value: old.value
                )

                try record.insert(db)
            }

            // BlockchainSettingRecord

            try BlockchainSettingRecord
                    .filter(BlockchainSettingRecord.Columns.blockchainUid == "bitcoinCash")
                    .updateAll(db, BlockchainSettingRecord.Columns.blockchainUid.set(to: "bitcoin-cash"))

            try BlockchainSettingRecord
                    .filter(BlockchainSettingRecord.Columns.blockchainUid == "binanceSmartChain")
                    .updateAll(db, BlockchainSettingRecord.Columns.blockchainUid.set(to: "binance-smart-chain"))

            // EnabledWallet

            let oldWallets = try EnabledWallet_v_0_25.fetchAll(db)

            try db.drop(table: EnabledWallet_v_0_25.databaseTableName)

            try db.create(table: EnabledWallet_v_0_34.databaseTableName) { t in
                t.column(EnabledWallet_v_0_34.Columns.tokenQueryId.name, .text).notNull()
                t.column(EnabledWallet_v_0_34.Columns.coinSettingsId.name, .text).notNull()
                t.column(EnabledWallet_v_0_34.Columns.accountId.name, .text).notNull()
                t.column(EnabledWallet_v_0_34.Columns.coinName.name, .text)
                t.column(EnabledWallet_v_0_34.Columns.coinCode.name, .text)
                t.column(EnabledWallet_v_0_34.Columns.tokenDecimals.name, .integer)

                t.primaryKey([EnabledWallet_v_0_34.Columns.tokenQueryId.name, EnabledWallet_v_0_34.Columns.coinSettingsId.name, EnabledWallet_v_0_34.Columns.accountId.name], onConflict: .replace)
            }

            for old in oldWallets {
                let record = EnabledWallet_v_0_34(
                        tokenQueryId: tokenQuery(coinTypeId: old.coinId).id,
                        coinSettingsId: old.coinSettingsId,
                        accountId: old.accountId,
                        coinName: old.coinName,
                        coinCode: old.coinCode,
                        tokenDecimals: old.coinDecimals
                )

                try record.insert(db)
            }

            // EnabledWalletCache_v_0_36

            if try db.tableExists("enabled_wallet_caches") {
                try db.drop(table: "enabled_wallet_caches")
            }

            try db.create(table: EnabledWalletCache_v_0_36.databaseTableName) { t in
                t.column(EnabledWalletCache_v_0_36.Columns.tokenQueryId.name, .text).notNull()
                t.column("coinSettingsId", .text).notNull()
                t.column(EnabledWalletCache_v_0_36.Columns.accountId.name, .text).notNull()
                t.column(EnabledWalletCache_v_0_36.Columns.balance.name, .text).notNull()
                t.column(EnabledWalletCache_v_0_36.Columns.balanceLocked.name, .text).notNull()

                t.primaryKey([EnabledWalletCache_v_0_36.Columns.tokenQueryId.name, EnabledWalletCache_v_0_36.Columns.accountId.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("createEvmAccountRestoreStates") { db in
            try db.create(table: EvmAccountRestoreState.databaseTableName) { t in
                t.column(EvmAccountRestoreState.Columns.accountId.name, .text).notNull()
                t.column(EvmAccountRestoreState.Columns.blockchainUid.name, .text).notNull()
                t.column(EvmAccountRestoreState.Columns.restored.name, .boolean).notNull()

                t.primaryKey([EvmAccountRestoreState.Columns.accountId.name, EvmAccountRestoreState.Columns.blockchainUid.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("checkBIP39Compliance") { db in
            try db.alter(table: AccountRecord_v_0_36.databaseTableName) { t in
                t.add(column: AccountRecord_v_0_36.Columns.bip39Compliant.name, .boolean)
            }
        }

        migrator.registerMigration("Create EvmSyncSourceRecord") { db in
            try db.create(table: EvmSyncSourceRecord.databaseTableName) { t in
                t.column(EvmSyncSourceRecord.Columns.blockchainTypeUid.name, .text).notNull()
                t.column(EvmSyncSourceRecord.Columns.url.name, .text).notNull()
                t.column(EvmSyncSourceRecord.Columns.auth.name, .text)

                t.primaryKey([EvmSyncSourceRecord.Columns.blockchainTypeUid.name, EvmSyncSourceRecord.Columns.url.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("Create CexAssetRecord") { db in
            try db.create(table: CexAssetRecord.databaseTableName) { t in
                t.column(CexAssetRecord.Columns.accountId.name, .text).notNull()
                t.column(CexAssetRecord.Columns.id.name, .text).notNull()
                t.column(CexAssetRecord.Columns.name.name, .text).notNull()
                t.column(CexAssetRecord.Columns.freeBalance.name, .text).notNull()
                t.column(CexAssetRecord.Columns.lockedBalance.name, .text).notNull()
                t.column(CexAssetRecord.Columns.withdrawEnabled.name, .boolean).notNull()
                t.column(CexAssetRecord.Columns.depositEnabled.name, .boolean).notNull()
                t.column(CexAssetRecord.Columns.depositNetworks.name, .text)
                t.column(CexAssetRecord.Columns.withdrawNetworks.name, .text)
                t.column(CexAssetRecord.Columns.coinUid.name, .text)

                t.primaryKey([CexAssetRecord.Columns.accountId.name, CexAssetRecord.Columns.id.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("Update EnabledWallet entities") { db in
            try db.drop(table: EnabledWalletCache_v_0_36.databaseTableName)
            try db.create(table: EnabledWalletCache_v_0_36.databaseTableName) { t in
                t.column(EnabledWalletCache_v_0_36.Columns.tokenQueryId.name, .text).notNull()
                t.column(EnabledWalletCache_v_0_36.Columns.accountId.name, .text).notNull()
                t.column(EnabledWalletCache_v_0_36.Columns.balance.name, .text).notNull()
                t.column(EnabledWalletCache_v_0_36.Columns.balanceLocked.name, .text).notNull()

                t.primaryKey([EnabledWalletCache_v_0_36.Columns.tokenQueryId.name, EnabledWalletCache_v_0_36.Columns.accountId.name], onConflict: .replace)
            }

            var enabledWallets: [EnabledWallet] = []
            let rows = try Row.fetchCursor(db, sql: "SELECT * FROM \(EnabledWallet_v_0_34.databaseTableName)")

            while let row = try rows.next() {
                guard let tokenQueryId = tokenQueryId(tokenQueryId: row["tokenQueryId"], coinSettingsId: row["coinSettingsId"]) else {
                    continue
                }

                let updatedWallet = EnabledWallet(
                    tokenQueryId: tokenQueryId,
                    accountId: row["accountId"], coinName: row["coinName"],
                    coinCode: row["coinCode"], tokenDecimals: row["tokenDecimals"]
                )

                enabledWallets.append(updatedWallet)
            }

            try db.drop(table: EnabledWallet_v_0_34.databaseTableName)
            try db.create(table: EnabledWallet.databaseTableName) { t in
                t.column(EnabledWallet.Columns.tokenQueryId.name, .text).notNull()
                t.column(EnabledWallet.Columns.accountId.name, .text).notNull()
                t.column(EnabledWallet.Columns.coinName.name, .text)
                t.column(EnabledWallet.Columns.coinCode.name, .text)
                t.column(EnabledWallet.Columns.tokenDecimals.name, .integer)

                t.primaryKey([EnabledWallet.Columns.tokenQueryId.name, EnabledWallet.Columns.accountId.name], onConflict: .replace)
            }

            for wallet in enabledWallets {
                try wallet.insert(db)
            }
        }

        migrator.registerMigration("Update EnabledWalletCache fields") { db in
            try db.drop(table: EnabledWalletCache_v_0_36.databaseTableName)
            try db.create(table: EnabledWalletCache.databaseTableName) { t in
                t.column(EnabledWalletCache.Columns.tokenQueryId.name, .text).notNull()
                t.column(EnabledWalletCache.Columns.accountId.name, .text).notNull()
                t.column(EnabledWalletCache.Columns.balances.name, .text).notNull()

                t.primaryKey([EnabledWalletCache.Columns.tokenQueryId.name, EnabledWalletCache.Columns.accountId.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("Add level and fileBackedUp to AccountRecord") { db in
            try db.alter(table: AccountRecord.databaseTableName) { t in
                t.add(column: AccountRecord.Columns.level.name, .integer).defaults(to: 0)
                t.add(column: AccountRecord.Columns.fileBackedUp.name, .boolean).defaults(to: false)
            }
        }

        migrator.registerMigration("Update ActiveAccount table") { db in
            let activeAccountId = try ActiveAccount_v_0_36.fetchOne(db)?.accountId

            try db.drop(table: ActiveAccount_v_0_36.databaseTableName)

            try db.create(table: ActiveAccount.databaseTableName) { t in
                t.column(ActiveAccount.Columns.level.name, .integer).notNull()
                t.column(ActiveAccount.Columns.accountId.name, .text).notNull()

                t.primaryKey([ActiveAccount.Columns.level.name], onConflict: .replace)
            }

            if let activeAccountId {
                try ActiveAccount(level: 0, accountId: activeAccountId).insert(db)
            }
        }

        try migrator.migrate(dbPool)
    }

    private static func tokenQuery(coinTypeId: String) -> TokenQuery {
        let coinType = CoinType(id: coinTypeId)

        switch coinType {
        case .bitcoin: return TokenQuery(blockchainType: .bitcoin, tokenType: .native)
        case .bitcoinCash: return TokenQuery(blockchainType: .bitcoinCash, tokenType: .native)
        case .litecoin: return TokenQuery(blockchainType: .litecoin, tokenType: .native)
        case .dash: return TokenQuery(blockchainType: .dash, tokenType: .native)
        case .zcash: return TokenQuery(blockchainType: .zcash, tokenType: .native)
        case .ethereum: return TokenQuery(blockchainType: .ethereum, tokenType: .native)
        case .binanceSmartChain: return TokenQuery(blockchainType: .binanceSmartChain, tokenType: .native)
        case .polygon: return TokenQuery(blockchainType: .polygon, tokenType: .native)
        case .ethereumOptimism: return TokenQuery(blockchainType: .optimism, tokenType: .native)
        case .ethereumArbitrumOne: return TokenQuery(blockchainType: .arbitrumOne, tokenType: .native)
        case .erc20(let address): return TokenQuery(blockchainType: .ethereum, tokenType: .eip20(address: address))
        case .bep20(let address): return TokenQuery(blockchainType: .binanceSmartChain, tokenType: .eip20(address: address))
        case .mrc20(let address): return TokenQuery(blockchainType: .polygon, tokenType: .eip20(address: address))
        case .optimismErc20(let address): return TokenQuery(blockchainType: .optimism, tokenType: .eip20(address: address))
        case .arbitrumOneErc20(let address): return TokenQuery(blockchainType: .arbitrumOne, tokenType: .eip20(address: address))
        case .bep2(let symbol): return symbol == "BNB" ? TokenQuery(blockchainType: .binanceChain, tokenType: .native) : TokenQuery(blockchainType: .binanceChain, tokenType: .bep2(symbol: symbol))
        default: return TokenQuery(blockchainType: .unsupported(uid: ""), tokenType: .unsupported(type: "", reference: nil))
        }
    }

    private static func tokenQueryId(tokenQueryId: String, coinSettingsId: String) -> String? {
        let chunks = tokenQueryId.split(separator: "|").map { String($0) }

        guard chunks.count == 2 else {
            return nil
        }

        let blockchainUid = chunks[0]
        let tokenType = chunks[1]

        let tokenTypeChunks = tokenType.split(separator: ":").map { String($0) }
        guard tokenTypeChunks.count == 1 && tokenTypeChunks[0] == "native" else {
            return tokenQueryId
        }

        switch blockchainUid {
            case "bitcoin", "litecoin":
                let chunks = coinSettingsId.split(separator: "|")

                for chunk in chunks {
                    let subChunks = chunk.split(separator: ":")

                    guard subChunks.count == 2 else {
                        continue
                    }

                    let settingsName = String(subChunks[0])
                    let derivation = String(subChunks[1])
                    guard settingsName == "derivation", ["bip44", "bip49", "bip84", "bip86"].contains(derivation) else {
                        continue
                    }

                    return "\(blockchainUid)|derived:\(derivation)"
                }


            case "bitcoin-cash":
                let chunks = coinSettingsId.split(separator: "|")

                for chunk in chunks {
                    let subChunks = chunk.split(separator: ":")

                    guard subChunks.count == 2 else {
                        continue
                    }

                    let settingsName = String(subChunks[0])
                    let addressType = String(subChunks[1])
                    guard settingsName == "bitcoinCashCoinType", ["type0", "type145"].contains(addressType) else {
                        continue
                    }

                    return "\(blockchainUid)|address_type:\(addressType)"
                }

            default:
                return tokenQueryId
        }

        return nil
    }

}
