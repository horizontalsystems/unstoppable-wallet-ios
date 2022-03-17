import Foundation
import RxSwift
import RxCocoa
import GRDB
import RxGRDB
import KeychainAccess
import HsToolKit
import MarketKit

class GrdbStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool

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
            try db.create(table: BlockchainSettingRecord.databaseTableName) { t in
                t.column(BlockchainSettingRecord.Columns.coinType.name, .text).notNull()
                t.column(BlockchainSettingRecord.Columns.key.name, .text).notNull()
                t.column(BlockchainSettingRecord.Columns.value.name, .text).notNull()

                t.primaryKey([BlockchainSettingRecord.Columns.coinType.name, BlockchainSettingRecord.Columns.key.name], onConflict: .replace)
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

            let derivationSettings: [BlockchainSettingRecord] = wallets.compactMap { wallet in
                guard
                        let coinTypeKey = coinTypeKeyMap[wallet.coinId],
                        let derivation = wallet.derivation
                        else {
                    return nil
                }

                return BlockchainSettingRecord(coinType: coinTypeKey, key: "derivation", value: derivation)
            }
            let syncSettings: [BlockchainSettingRecord] = wallets.compactMap { wallet in
                guard
                        let coinTypeKey = coinTypeKeyMap[wallet.coinId],
                        let syncMode = wallet.syncMode
                        else {
                    return nil
                }

                return BlockchainSettingRecord(coinType: coinTypeKey, key: "sync_mode", value: syncMode)
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
                let record = BlockchainSettingRecord(coinType: "bitcoinCash", key: "network_coin_type", value: "type0")
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

        migrator.registerMigration("createWalletConnectSessions") { db in
            try db.create(table: WalletConnectSession.databaseTableName) { t in
                t.column(WalletConnectSession.Columns.chainId.name, .integer).notNull()
                t.column(WalletConnectSession.Columns.accountId.name, .text).notNull()
                t.column(WalletConnectSession.Columns.session.name, .text).notNull()
                t.column(WalletConnectSession.Columns.peerId.name, .text).notNull()
                t.column(WalletConnectSession.Columns.peerMeta.name, .text).notNull()

                t.primaryKey([WalletConnectSession.Columns.chainId.name, WalletConnectSession.Columns.accountId.name, WalletConnectSession.Columns.peerId.name], onConflict: .replace)
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
            try db.create(table: ActiveAccount.databaseTableName) { t in
                t.column(ActiveAccount.Columns.uniqueId.name, .text).notNull()
                t.column(ActiveAccount.Columns.accountId.name, .text).notNull()

                t.primaryKey([ActiveAccount.Columns.uniqueId.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("createRestoreSettings") { db in
            try db.create(table: RestoreSettingRecord.databaseTableName) { t in
                t.column(RestoreSettingRecord.Columns.accountId.name, .text).notNull()
                t.column(RestoreSettingRecord.Columns.coinId.name, .text).notNull()
                t.column(RestoreSettingRecord.Columns.key.name, .text).notNull()
                t.column(RestoreSettingRecord.Columns.value.name, .text)

                t.primaryKey([RestoreSettingRecord.Columns.accountId.name, RestoreSettingRecord.Columns.coinId.name, RestoreSettingRecord.Columns.key.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("moveCoinSettingsFromBlockchainSettingsToWallet") { db in
            let oldAccounts = try AccountRecord_v_0_20.fetchAll(db)

            try db.drop(table: AccountRecord_v_0_20.databaseTableName)

            try db.create(table: AccountRecord.databaseTableName) { t in
                t.column(AccountRecord.Columns.id.name, .text).notNull()
                t.column(AccountRecord.Columns.name.name, .text).notNull()
                t.column(AccountRecord.Columns.type.name, .text).notNull()
                t.column(AccountRecord.Columns.origin.name, .text).notNull()
                t.column(AccountRecord.Columns.backedUp.name, .boolean).notNull()
                t.column(AccountRecord.Columns.wordsKey.name, .text)
                t.column(AccountRecord.Columns.saltKey.name, .text)
                t.column(AccountRecord.Columns.dataKey.name, .text)

                t.primaryKey([AccountRecord.Columns.id.name], onConflict: .replace)
            }

            for (index, oldAccount) in oldAccounts.enumerated() {
                var accountType = oldAccount.type

                if accountType == "zcash" {
                    let keychain = Keychain(service: "io.horizontalsystems.bank.dev")

                    let key = "zcash_\(oldAccount.id)_birthdayHeight"
                    if let birthdayHeightString = keychain[key], let birthdayHeight = Int(birthdayHeightString) {
                        let restoreSetting = RestoreSettingRecord(accountId: oldAccount.id, coinId: "zcash", key: "birthdayHeight", value: String(birthdayHeight))
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

                let newAccount = AccountRecord(
                        id: oldAccount.id,
                        name: "Wallet \(index + 1)",
                        type: accountType,
                        origin: oldAccount.origin,
                        backedUp: oldAccount.backedUp,
                        wordsKey: oldAccount.wordsKey,
                        saltKey: oldAccount.saltKey,
                        dataKey: oldAccount.dataKey
                )

                try newAccount.insert(db)

                if index == 0 {
                    let activeAccount = ActiveAccount(accountId: oldAccount.id)
                    try activeAccount.insert(db)
                }
            }

            let oldWallets = try EnabledWallet_v_0_20.fetchAll(db)

            try db.drop(table: EnabledWallet_v_0_20.databaseTableName)

            try db.create(table: EnabledWallet.databaseTableName) { t in
                t.column(EnabledWallet.Columns.coinId.name, .text).notNull()
                t.column(EnabledWallet.Columns.coinSettingsId.name, .text).notNull()
                t.column(EnabledWallet.Columns.accountId.name, .text).notNull()

                t.primaryKey([EnabledWallet.Columns.coinId.name, EnabledWallet.Columns.coinSettingsId.name, EnabledWallet.Columns.accountId.name], onConflict: .replace)
            }

            let settingRecords = try BlockchainSettingRecord.fetchAll(db)

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

                let newWallet = EnabledWallet(
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
            let records = try AccountRecord.fetchAll(db)

            for record in records {
                try keychain.set("", key: "mnemonic_\(record.id)_salt")
            }
        }

        migrator.registerMigration("createAccountSettings") { db in
            try db.create(table: AccountSettingRecord.databaseTableName) { t in
                t.column(AccountSettingRecord.Columns.accountId.name, .text).notNull()
                t.column(AccountSettingRecord.Columns.key.name, .text).notNull()
                t.column(AccountSettingRecord.Columns.value.name, .text).notNull()

                t.primaryKey([AccountSettingRecord.Columns.accountId.name, AccountSettingRecord.Columns.key.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("createEnabledWalletCaches") { db in
            try db.create(table: EnabledWalletCache.databaseTableName) { t in
                t.column(EnabledWalletCache.Columns.coinId.name, .text).notNull()
                t.column(EnabledWalletCache.Columns.coinSettingsId.name, .text).notNull()
                t.column(EnabledWalletCache.Columns.accountId.name, .text).notNull()
                t.column(EnabledWalletCache.Columns.balance.name, .text).notNull()
                t.column(EnabledWalletCache.Columns.balanceLocked.name, .text).notNull()

                t.primaryKey([EnabledWalletCache.Columns.coinId.name, EnabledWalletCache.Columns.coinSettingsId.name, EnabledWalletCache.Columns.accountId.name], onConflict: .replace)
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

        migrator.registerMigration("createEvmAccountSyncStates") { db in
            try db.create(table: EvmAccountSyncState.databaseTableName) { t in
                t.column(EvmAccountSyncState.Columns.accountId.name, .text).notNull()
                t.column(EvmAccountSyncState.Columns.chainId.name, .integer).notNull()
                t.column(EvmAccountSyncState.Columns.lastBlockNumber.name, .integer).notNull()

                t.primaryKey([EvmAccountSyncState.Columns.accountId.name, EvmAccountSyncState.Columns.chainId.name], onConflict: .replace)
            }
        }

        migrator.registerMigration("createWalletConnectV2Sessions") { db in
            try db.create(table: WalletConnectV2Session.databaseTableName) { t in
                t.column(WalletConnectV2Session.Columns.accountId.name, .text).notNull()
                t.column(WalletConnectV2Session.Columns.topic.name, .text).notNull()

                t.primaryKey([WalletConnectV2Session.Columns.accountId.name, WalletConnectV2Session.Columns.topic.name], onConflict: .replace)
            }
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

    func enabledWallets(accountId: String) -> [EnabledWallet] {
        try! dbPool.read { db in
            try EnabledWallet.filter(EnabledWallet.Columns.accountId == accountId).fetchAll(db)
        }
    }

    func handle(newEnabledWallets: [EnabledWallet], deletedEnabledWallets: [EnabledWallet]) {
        _ = try! dbPool.write { db in
            for enabledWallet in newEnabledWallets {
                try enabledWallet.insert(db)
            }
            for enabledWallet in deletedEnabledWallets {
                try EnabledWallet.filter(EnabledWallet.Columns.coinId == enabledWallet.coinId && EnabledWallet.Columns.coinSettingsId == enabledWallet.coinSettingsId && EnabledWallet.Columns.accountId == enabledWallet.accountId).deleteAll(db)
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

extension GrdbStorage: IAppVersionRecordStorage {

    var appVersionRecords: [AppVersionRecord] {
        try! dbPool.read { db in
            try AppVersionRecord.fetchAll(db)
        }
    }

    func save(appVersionRecords: [AppVersionRecord]) {
        _ = try! dbPool.write { db in
            for record in appVersionRecords {
                try record.insert(db)
            }
        }
    }

}

extension GrdbStorage: IBlockchainSettingsRecordStorage {

    func blockchainSettings(coinTypeKey: String, settingKey: String) -> BlockchainSettingRecord? {
        try? dbPool.read { db in
            try BlockchainSettingRecord.filter(BlockchainSettingRecord.Columns.coinType == coinTypeKey && BlockchainSettingRecord.Columns.key == settingKey).fetchOne(db)
        }
    }

    func save(blockchainSetting: BlockchainSettingRecord) {
        _ = try! dbPool.write { db in
            try blockchainSetting.insert(db)
        }
    }

    func deleteAll(settingKey: String) {
        _ = try! dbPool.write { db in
            try BlockchainSettingRecord.filter(BlockchainSettingRecord.Columns.key == settingKey).deleteAll(db)
        }
    }

}

extension GrdbStorage: IFavoriteCoinRecordStorage {

    var favoriteCoinRecords: [FavoriteCoinRecord] {
        try! dbPool.read { db in
            try FavoriteCoinRecord.fetchAll(db)
        }
    }

    func save(favoriteCoinRecord: FavoriteCoinRecord) {
        _ = try! dbPool.write { db in
            try favoriteCoinRecord.insert(db)
        }
    }

    func save(favoriteCoinRecords: [FavoriteCoinRecord]) {
        _ = try! dbPool.write { db in
            for record in favoriteCoinRecords {
                try record.insert(db)
            }
        }
    }

    func deleteFavoriteCoinRecord(coinUid: String) {
        _ = try! dbPool.write { db in
            try FavoriteCoinRecord
                    .filter(FavoriteCoinRecord.Columns.coinUid == coinUid)
                    .deleteAll(db)
        }
    }

    func favoriteCoinRecordExists(coinUid: String) -> Bool {
        try! dbPool.read { db in
            try FavoriteCoinRecord
                    .filter(FavoriteCoinRecord.Columns.coinUid == coinUid)
                    .fetchCount(db) > 0
        }
    }

    var favoriteCoinRecords_v_0_22: [FavoriteCoinRecord_v_0_22] {
        try! dbPool.read { db in
            try FavoriteCoinRecord_v_0_22.fetchAll(db)
        }
    }

}

extension GrdbStorage: ILogRecordStorage {

    func logs(context: String) -> [LogRecord] {
        try! dbPool.read { db in
            try LogRecord
                    .filter(LogRecord.Columns.context.like("\(context)%"))
                    .order(LogRecord.Columns.date.asc)
                    .fetchAll(db)
        }
    }

    func save(logRecord: LogRecord) {
        _ = try? dbPool.write { db in
            try logRecord.insert(db)
        }
    }

    func logsCount() -> Int {
        try! dbPool.read { db in
            try LogRecord.fetchCount(db)
        }
    }

    func removeFirstLogs(count: Int) {
        _ = try! dbPool.write { db in
            let logs = try LogRecord.order(LogRecord.Columns.date.asc).limit(count).fetchAll(db)
            if let last = logs.last {
                try LogRecord.filter(LogRecord.Columns.date <= last.date).deleteAll(db)
            }
        }
    }

}

extension GrdbStorage: IWalletConnectSessionStorage {

    func sessions(accountId: String) -> [WalletConnectSession] {
        try! dbPool.read { db in
            try WalletConnectSession.filter(WalletConnectSession.Columns.accountId == accountId).fetchAll(db)
        }
    }

    func session(peerId: String, accountId: String) -> WalletConnectSession? {
        try! dbPool.read { db in
            try WalletConnectSession.filter(WalletConnectSession.Columns.peerId == peerId && WalletConnectSession.Columns.accountId == accountId).fetchOne(db)
        }
    }

    func save(session: WalletConnectSession) {
        _ = try! dbPool.write { db in
            try session.insert(db)
        }
    }

    func deleteSession(peerId: String) {
        _ = try! dbPool.write { db in
            try WalletConnectSession.filter(WalletConnectSession.Columns.peerId == peerId).deleteAll(db)
        }
    }

    func deleteSessions(accountId: String) {
        _ = try! dbPool.write { db in
            try WalletConnectSession.filter(WalletConnectSession.Columns.accountId == accountId).deleteAll(db)
        }
    }

}

extension GrdbStorage: IWalletConnectV2SessionStorage {

    func sessionsV2(accountId: String?) -> [WalletConnectV2Session] {
        try! dbPool.read { db in
            var request = WalletConnectV2Session.all()
            if let accountId = accountId {
                request = request.filter(WalletConnectV2Session.Columns.accountId == accountId)
            }
            return try request.fetchAll(db)
        }
    }

    func save(sessions: [WalletConnectV2Session]) {
        _ = try! dbPool.write { db in
            for session in sessions {
                try session.insert(db)
            }
        }
    }

    func deleteSessionV2(topics: [String]) {
        _ = try! dbPool.write { db in
            for topic in topics {
                try WalletConnectV2Session.filter(WalletConnectV2Session.Columns.topic == topic).deleteAll(db)
            }
        }
    }

    func deleteSessionsV2(accountId: String) {
        _ = try! dbPool.write { db in
            try WalletConnectV2Session.filter(WalletConnectV2Session.Columns.accountId == accountId).deleteAll(db)
        }
    }

}

extension GrdbStorage: IActiveAccountStorage {

    var activeAccountId: String? {
        get {
            try! dbPool.read { db in
                try ActiveAccount.fetchOne(db)?.accountId
            }
        }
        set {
            _ = try! dbPool.write { db in
                if let accountId = newValue {
                    try ActiveAccount(accountId: accountId).insert(db)
                } else {
                    try ActiveAccount.deleteAll(db)
                }
            }
        }
    }

}

extension GrdbStorage: IRestoreSettingsStorage {

    func restoreSettings(accountId: String, coinId: String) -> [RestoreSettingRecord] {
        try! dbPool.read { db in
            try RestoreSettingRecord.filter(RestoreSettingRecord.Columns.accountId == accountId && RestoreSettingRecord.Columns.coinId == coinId).fetchAll(db)
        }
    }

    func restoreSettings(accountId: String) -> [RestoreSettingRecord] {
        try! dbPool.read { db in
            try RestoreSettingRecord.filter(RestoreSettingRecord.Columns.accountId == accountId).fetchAll(db)
        }
    }

    func save(restoreSettingRecords: [RestoreSettingRecord]) {
        _ = try! dbPool.write { db in
            for record in restoreSettingRecords {
                try record.insert(db)
            }
        }
    }

    func deleteAllRestoreSettings(accountId: String) {
        _ = try! dbPool.write { db in
            try RestoreSettingRecord.filter(RestoreSettingRecord.Columns.accountId == accountId).deleteAll(db)
        }
    }

}

extension GrdbStorage: IAccountSettingRecordStorage {

    func accountSetting(accountId: String, key: String) -> AccountSettingRecord? {
        try! dbPool.read { db in
            try AccountSettingRecord.filter(AccountSettingRecord.Columns.accountId == accountId && AccountSettingRecord.Columns.key == key).fetchOne(db)
        }
    }

    func save(accountSetting: AccountSettingRecord) {
        _ = try! dbPool.write { db in
            try accountSetting.insert(db)
        }
    }

    func deleteAllAccountSettings(accountId: String) {
        _ = try! dbPool.write { db in
            try AccountSettingRecord.filter(AccountSettingRecord.Columns.accountId == accountId).deleteAll(db)
        }
    }

}

extension GrdbStorage: IEnabledWalletCacheStorage {

    func enabledWalletCaches(accountId: String) -> [EnabledWalletCache] {
        try! dbPool.read { db in
            try EnabledWalletCache.filter(EnabledWalletCache.Columns.accountId == accountId).fetchAll(db)
        }

    }

    func save(enabledWalletCaches: [EnabledWalletCache]) {
        _ = try! dbPool.write { db in
            for cache in enabledWalletCaches {
                try cache.insert(db)
            }
        }
    }

    func deleteEnabledWalletCaches(accountId: String) {
        _ = try! dbPool.write { db in
            try EnabledWalletCache.filter(EnabledWalletCache.Columns.accountId == accountId).deleteAll(db)
        }
    }

}

extension GrdbStorage: ICustomTokenStorage {

    func customTokens(platformType: PlatformType, filter: String) -> [CustomToken] {
        try! dbPool.read { db in
            try CustomToken
                    .filter(CustomToken.Columns.coinName.like("%\(filter)%") || CustomToken.Columns.coinCode.like("%\(filter)%"))
                    .filter(platformType.coinTypeIdPrefixes.map { CustomToken.Columns.coinTypeId.like("\($0)%") }.joined(operator: .or))
                    .fetchAll(db)
        }
    }

    func customTokens(filter: String) -> [CustomToken] {
        try! dbPool.read { db in
            try CustomToken
                    .filter(CustomToken.Columns.coinName.like("%\(filter)%") || CustomToken.Columns.coinCode.like("%\(filter)%"))
                    .order(CustomToken.Columns.coinName.asc)
                    .fetchAll(db)
        }
    }

    func customTokens(coinTypeIds: [String]) -> [CustomToken] {
        try! dbPool.read { db in
            try CustomToken
                    .filter(coinTypeIds.contains(CustomToken.Columns.coinTypeId))
                    .fetchAll(db)
        }
    }

    func customToken(coinType: MarketKit.CoinType) -> CustomToken? {
        try! dbPool.read { db in
            try CustomToken
                    .filter(CustomToken.Columns.coinTypeId == coinType.id)
                    .fetchOne(db)
        }
    }

    func save(customTokens: [CustomToken]) {
        _ = try! dbPool.write { db in
            for customToken in customTokens {
                try customToken.insert(db)
            }
        }
    }

}

extension GrdbStorage: IEvmAccountSyncStateStorage {

    func evmAccountSyncState(accountId: String, chainId: Int) -> EvmAccountSyncState? {
        try! dbPool.read { db in
            try EvmAccountSyncState.filter(EvmAccountSyncState.Columns.accountId == accountId && EvmAccountSyncState.Columns.chainId == chainId).fetchOne(db)
        }
    }

    func save(evmAccountSyncState: EvmAccountSyncState) {
        _ = try! dbPool.write { db in
            try evmAccountSyncState.insert(db)
        }
    }

}
