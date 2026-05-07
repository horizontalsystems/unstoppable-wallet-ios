import Foundation
import MarketKit

class AppBackupProvider {
    private static let version = 2

    private let accountManager: AccountManager
    private let accountFactory: AccountFactory
    private let walletManager: WalletManager
    private let watchlistManager: WatchlistManager
    private let evmSyncSourceManager: EvmSyncSourceManager
    private let moneroNodeManager: MoneroNodeManager
    private let zanoNodeManager: ZanoNodeManager
    private let btcBlockchainManager: BtcBlockchainManager
    private let restoreSettingsManager: RestoreSettingsManager
    private let chartRepository: ChartIndicatorsRepository
    private let localStorage: LocalStorage
    private let languageManager: LanguageManager
    private let currencyManager: CurrencyManager
    private let themeManager: ThemeManager
    private let launchScreenManager: LaunchScreenManager
    private let appIconManager: AppIconManager
    private let appSettingManager: AppSettingManager
    private let balanceConversionManager: BalanceConversionManager
    private let balanceHiddenManager: BalanceHiddenManager
    private let contactManager: ContactBookManager
    private let priceChangeModeManager: PriceChangeModeManager
    private let walletButtonHiddenManager: WalletButtonHiddenManager

    init(accountManager: AccountManager,
         accountFactory: AccountFactory,
         walletManager: WalletManager,
         watchlistManager: WatchlistManager,
         evmSyncSourceManager: EvmSyncSourceManager,
         moneroNodeManager: MoneroNodeManager,
         zanoNodeManager: ZanoNodeManager,
         btcBlockchainManager: BtcBlockchainManager,
         restoreSettingsManager: RestoreSettingsManager,
         chartRepository: ChartIndicatorsRepository,
         localStorage: LocalStorage,
         languageManager: LanguageManager,
         currencyManager: CurrencyManager,
         themeManager: ThemeManager,
         launchScreenManager: LaunchScreenManager,
         appIconManager: AppIconManager,
         appSettingManager: AppSettingManager,
         balanceConversionManager: BalanceConversionManager,
         balanceHiddenManager: BalanceHiddenManager,
         contactManager: ContactBookManager,
         priceChangeModeManager: PriceChangeModeManager,
         walletButtonHiddenManager: WalletButtonHiddenManager)
    {
        self.accountManager = accountManager
        self.accountFactory = accountFactory
        self.walletManager = walletManager
        self.watchlistManager = watchlistManager
        self.evmSyncSourceManager = evmSyncSourceManager
        self.moneroNodeManager = moneroNodeManager
        self.zanoNodeManager = zanoNodeManager
        self.btcBlockchainManager = btcBlockchainManager
        self.restoreSettingsManager = restoreSettingsManager
        self.chartRepository = chartRepository
        self.localStorage = localStorage
        self.languageManager = languageManager
        self.currencyManager = currencyManager
        self.themeManager = themeManager
        self.launchScreenManager = launchScreenManager
        self.appIconManager = appIconManager
        self.appSettingManager = appSettingManager
        self.balanceConversionManager = balanceConversionManager
        self.balanceHiddenManager = balanceHiddenManager
        self.contactManager = contactManager
        self.priceChangeModeManager = priceChangeModeManager
        self.walletButtonHiddenManager = walletButtonHiddenManager
    }

    // Parts of backups
    func enabledWallets(account: Account) -> [WalletBackup.EnabledWallet] {
        walletManager
            .wallets(account: account).map {
                let settings = restoreSettingsManager
                    .settings(accountId: account.id, blockchainType: $0.token.blockchainType)
                    .reduce(into: [:]) { $0[$1.0.rawValue] = $1.1 }

                return WalletBackup.EnabledWallet($0, settings: settings)
            }
    }

    private var swapProviders: [SettingsBackup.DefaultProvider] {
        EvmBlockchainManager
            .blockchainTypes
            .map {
                SettingsBackup.DefaultProvider(
                    blockchainTypeId: $0.uid,
                    provider: localStorage.defaultProvider(blockchainType: $0).id
                )
            }
    }

    private func defaultSettings(evmSyncSources: EvmSyncSourceManager.SyncSourceBackup, moneroNodes: MoneroNodeManager.NodeBackup, zanoNodes: ZanoNodeManager.NodeBackup) -> SettingsBackup {
        SettingsBackup(
            evmSyncSources: evmSyncSources,
            moneroNodes: moneroNodes,
            zanoNodes: zanoNodes,
            btcModes: [],
            remoteContactsSync: nil,
            swapProviders: [],
            chartIndicators: .init(
                ma: [
                    .init(period: 9, type: "ema", enabled: false),
                    .init(period: 25, type: "ema", enabled: false),
                    .init(period: 50, type: "ema", enabled: false),
                ],
                rsi: [.init(period: 12, enabled: false)],
                macd: [.init(slow: 26, fast: 12, signal: 9, enabled: false)]
            ),
            indicatorsShown: true,
            currentLanguage: "en",
            baseCurrency: "USD",
            mode: .system,
            showMarketTab: true,
            priceChangeMode: .hour24,
            launchScreen: .auto,
            conversionTokenQueryId: nil,
            balanceHideButtons: false,
            balancePrimaryValue: .coin,
            balanceAutoHide: false,
            appIcon: "Main"
        )
    }

    private func settings(evmSyncSources: EvmSyncSourceManager.SyncSourceBackup, moneroNodes: MoneroNodeManager.NodeBackup, zanoNodes: ZanoNodeManager.NodeBackup) -> SettingsBackup {
        SettingsBackup(
            evmSyncSources: evmSyncSources,
            moneroNodes: moneroNodes,
            zanoNodes: zanoNodes,
            btcModes: btcBlockchainManager.backup,
            remoteContactsSync: localStorage.remoteContactsSync,
            swapProviders: swapProviders,
            chartIndicators: chartRepository.backup,
            indicatorsShown: localStorage.indicatorsShown,
            currentLanguage: languageManager.currentLanguage,
            baseCurrency: currencyManager.baseCurrency.code,
            mode: themeManager.themeMode,
            showMarketTab: launchScreenManager.showMarket,
            priceChangeMode: priceChangeModeManager.priceChangeMode,
            launchScreen: launchScreenManager.launchScreen,
            conversionTokenQueryId: balanceConversionManager.conversionToken?.tokenQuery.id,
            balanceHideButtons: walletButtonHiddenManager.buttonHidden,
            balancePrimaryValue: appSettingManager.balancePrimaryValue,
            balanceAutoHide: balanceHiddenManager.balanceAutoHide,
            appIcon: appIconManager.appIcon.title
        )
    }

    func encrypt(accountIds: [String], passphrase: String) throws -> [CloudRestoreBackupListModule.RestoredBackup] {
        try accountIds.compactMap {
            accountManager.account(id: $0)
        }.compactMap {
            let walletBackup = try Self.encrypt(account: $0, wallets: enabledWallets(account: $0), passphrase: passphrase)
            return CloudRestoreBackupListModule.RestoredBackup(name: $0.name, walletBackup: walletBackup)
        }
    }

    func fullBackup(accountIds: [String], sections: Set<BackupSection> = Set(BackupSection.allCases)) -> RawFullBackup {
        let accounts = accountIds
            .compactMap { accountManager.account(id: $0) }
            .compactMap { RawWalletBackup(account: $0, enabledWallets: enabledWallets(account: $0)) }

        let includeCustomRpc = sections.contains(.customRpc)
        let includePreferences = sections.contains(.preferences)

        let syncSources: EvmSyncSourceManager.SyncSourceBackup
        let moneroNodeBackup: MoneroNodeManager.NodeBackup
        let zanoNodeBackup: ZanoNodeManager.NodeBackup

        if includeCustomRpc {
            syncSources = EvmSyncSourceManager.SyncSourceBackup(selected: evmSyncSourceManager.selectedSources, custom: [])
            moneroNodeBackup = MoneroNodeManager.NodeBackup(selected: moneroNodeManager.selectedNodes, custom: [])
            zanoNodeBackup = ZanoNodeManager.NodeBackup(selected: zanoNodeManager.selectedNodes, custom: [])
        } else {
            syncSources = .init(selected: [], custom: [])
            moneroNodeBackup = .init(selected: [], custom: [])
            zanoNodeBackup = .init(selected: [], custom: [])
        }

        let settingsBackup: SettingsBackup
        if includePreferences {
            settingsBackup = settings(evmSyncSources: syncSources, moneroNodes: moneroNodeBackup, zanoNodes: zanoNodeBackup)
        } else {
            settingsBackup = defaultSettings(evmSyncSources: syncSources, moneroNodes: moneroNodeBackup, zanoNodes: zanoNodeBackup)
        }

        return RawFullBackup(
            accounts: accounts,
            watchlistIds: sections.contains(.favourites) ? watchlistManager.coinUids : [],
            contacts: sections.contains(.contacts) ? (contactManager.backupContactBook?.contacts ?? []) : [],
            settings: settingsBackup,
            customSyncSources: includeCustomRpc ? evmSyncSourceManager.customSources : [],
            customMoneroNodes: includeCustomRpc ? moneroNodeManager.customNodeRecords : [],
            customZanoNodes: includeCustomRpc ? zanoNodeManager.customNodeRecords : [],
            sections: sections
        )
    }
}

extension AppBackupProvider {
    func restore(raws: [RawWalletBackup]) {
        let updated = raws.map { raw in
            let account = accountFactory.account(
                type: raw.account.type,
                origin: raw.account.origin,
                backedUp: raw.account.backedUp,
                fileBackedUp: raw.account.fileBackedUp,
                name: raw.account.name
            )
            return RawWalletBackup(account: account, enabledWallets: raw.enabledWallets)
        }

        accountManager.save(accounts: updated.map(\.account))

        for raw in updated {
            let wallets = raw.enabledWallets.compactMap { (wallet: WalletBackup.EnabledWallet) -> EnabledWallet? in
                guard let tokenQuery = TokenQuery(id: wallet.tokenQueryId),
                      BlockchainType.supported.contains(tokenQuery.blockchainType)
                else {
                    return nil
                }

                if !wallet.settings.isEmpty {
                    var restoreSettings = [RestoreSettingType: String]()
                    for (key, value) in wallet.settings {
                        if let key = RestoreSettingType(rawValue: key) {
                            restoreSettings[key] = value
                        }
                    }
                    restoreSettingsManager.save(settings: restoreSettings, account: raw.account, blockchainType: tokenQuery.blockchainType)
                }

                return EnabledWallet(
                    tokenQueryId: wallet.tokenQueryId,
                    accountId: raw.account.id,
                    coinName: wallet.coinName,
                    coinCode: wallet.coinCode,
                    tokenDecimals: wallet.tokenDecimals
                )
            }
            walletManager.save(enabledWallets: wallets)
        }
    }

    func restore(raw: RawFullBackup, accountIds: Set<String>? = nil, sections: Set<BackupSection> = Set(BackupSection.allCases)) {
        let accountsToRestore: [RawWalletBackup]
        if let accountIds {
            accountsToRestore = raw.accounts.filter { accountIds.contains($0.account.id) }
        } else {
            accountsToRestore = raw.accounts
        }

        for wallet in accountsToRestore {
            restore(raws: [wallet])
        }

        if sections.contains(.favourites) {
            watchlistManager.add(coinUids: raw.watchlistIds)
        }

        if sections.contains(.contacts), !raw.contacts.isEmpty {
            try? contactManager.restore(contacts: raw.contacts, mergePolitics: .replace)
        }

        if sections.contains(.customRpc) {
            evmSyncSourceManager.restore(selected: raw.settings.evmSyncSources.selected, custom: raw.customSyncSources)
            moneroNodeManager.restore(selected: raw.settings.moneroNodes.selected, custom: raw.customMoneroNodes)
            zanoNodeManager.restore(selected: raw.settings.zanoNodes.selected, custom: raw.customZanoNodes)
        }

        if sections.contains(.preferences) {
            btcBlockchainManager.restore(backup: raw.settings.btcModes)
            chartRepository.restore(backup: raw.settings.chartIndicators)
            localStorage.restore(backup: raw.settings)
            languageManager.currentLanguage = raw.settings.currentLanguage
            if let currency = currencyManager.currencies.first(where: { $0.code == raw.settings.baseCurrency }) {
                currencyManager.baseCurrency = currency
            }

            themeManager.themeMode = raw.settings.mode
            launchScreenManager.showMarket = raw.settings.showMarketTab
            launchScreenManager.launchScreen = raw.settings.launchScreen
            priceChangeModeManager.priceChangeMode = raw.settings.priceChangeMode
            appSettingManager.balancePrimaryValue = raw.settings.balancePrimaryValue

            walletButtonHiddenManager.buttonHidden = raw.settings.balanceHideButtons
            balanceConversionManager.set(tokenQueryId: raw.settings.conversionTokenQueryId)
            balanceHiddenManager.set(balanceAutoHide: raw.settings.balanceAutoHide)
            let appIcon = AppIconManager.allAppIcons.first { $0.title == raw.settings.appIcon } ?? .main
            if appIconManager.appIcon != appIcon {
                appIconManager.appIcon = appIcon
            }
        }
    }
}

extension AppBackupProvider {
    func decrypt(walletBackup: WalletBackup, name: String, passphrase: String) throws -> RawWalletBackup {
        let accountType = try AccountType.decrypt(
            crypto: walletBackup.crypto,
            type: walletBackup.type,
            passphrase: passphrase
        )
        let account = accountFactory.account(
            type: accountType,
            origin: .restored,
            backedUp: walletBackup.isManualBackedUp,
            fileBackedUp: walletBackup.isFileBackedUp,
            name: name
        )

        return RawWalletBackup(account: account, enabledWallets: walletBackup.enabledWallets)
    }

    func decrypt(fullBackup: FullBackup, passphrase: String) throws -> RawFullBackup {
        let wallets = try fullBackup.wallets
            .map { try decrypt(walletBackup: $0.walletBackup, name: $0.name, passphrase: passphrase) }

        let contacts = try fullBackup.contacts.map { try ContactBookManager.decrypt(crypto: $0, passphrase: passphrase) }

        let customSources = try evmSyncSourceManager.decrypt(sources: fullBackup.settings.evmSyncSources.custom, passphrase: passphrase)
        let customMoneroNodes = try moneroNodeManager.decrypt(nodes: fullBackup.settings.moneroNodes.custom, passphrase: passphrase)
        let customZanoNodes = zanoNodeManager.decode(nodes: fullBackup.settings.zanoNodes.custom)

        return RawFullBackup(
            accounts: wallets,
            watchlistIds: fullBackup.watchlistIds,
            contacts: contacts ?? [],
            settings: fullBackup.settings,
            customSyncSources: customSources,
            customMoneroNodes: customMoneroNodes,
            customZanoNodes: customZanoNodes,
            sections: fullBackup.sections
        )
    }

    func encrypt(raw: RawFullBackup, passphrase: String, sections: Set<BackupSection>? = nil) throws -> FullBackup {
        let wallets = try raw.accounts.map {
            let walletBackup = try Self.encrypt(account: $0.account, wallets: $0.enabledWallets, passphrase: passphrase)
            return CloudRestoreBackupListModule.RestoredBackup(name: $0.account.name, walletBackup: walletBackup)
        }

        let contacts = try ContactBookManager.encrypt(contacts: raw.contacts, passphrase: passphrase)
        let customEvmSyncSource = try evmSyncSourceManager.encrypt(sources: raw.customSyncSources, passphrase: passphrase)
        let customMoneroNode = try moneroNodeManager.encrypt(nodes: raw.customMoneroNodes, passphrase: passphrase)
        let customZanoNode = zanoNodeManager.encode(nodes: raw.customZanoNodes)
        let settingsBackup = raw.settings.withEncryptedCustom(
            evmSyncSources: .init(selected: raw.settings.evmSyncSources.selected, custom: customEvmSyncSource),
            moneroNodes: .init(selected: raw.settings.moneroNodes.selected, custom: customMoneroNode),
            zanoNodes: .init(selected: raw.settings.zanoNodes.selected, custom: customZanoNode)
        )

        return FullBackup(
            id: UUID().uuidString,
            wallets: wallets,
            watchlistIds: raw.watchlistIds,
            contacts: contacts,
            settings: settingsBackup,
            sections: sections,
            version: AppBackupProvider.version,
            timestamp: Date().timeIntervalSince1970.rounded()
        )
    }

    static func encrypt(account: Account, wallets: [WalletBackup.EnabledWallet], passphrase: String) throws -> WalletBackup {
        let message = account.type.uniqueId(hashed: false)
        let crypto = try BackupCrypto.encrypt(data: message, passphrase: passphrase)

        return WalletBackup(
            crypto: crypto,
            enabledWallets: wallets,
            id: account.type.uniqueId().hs.hex,
            type: AccountType.Abstract(account.type),
            isManualBackedUp: account.backedUp,
            isFileBackedUp: account.fileBackedUp,
            version: Self.version,
            timestamp: Date().timeIntervalSince1970.rounded()
        )
    }
}

extension AppBackupProvider {
    enum CodingError: Error {
        case invalidPassword
        case emptyParameters
    }
}
