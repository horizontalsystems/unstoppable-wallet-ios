import CurrencyKit
import Foundation
import LanguageKit
import MarketKit
import ThemeKit

class AppBackupProvider {
    private static let version = 2

    private let accountManager: AccountManager
    private let accountFactory: AccountFactory
    private let walletManager: WalletManager
    private let favoritesManager: FavoritesManager
    private let evmSyncSourceManager: EvmSyncSourceManager
    private let btcBlockchainManager: BtcBlockchainManager
    private let restoreSettingsManager: RestoreSettingsManager
    private let chartRepository: ChartIndicatorsRepository
    private let localStorage: LocalStorage
    private let languageManager: LanguageManager
    private let currencyKit: CurrencyKit.Kit
    private let themeManager: ThemeManager
    private let launchScreenManager: LaunchScreenManager
    private let appIconManager: AppIconManager
    private let balancePrimaryValueManager: BalancePrimaryValueManager
    private let balanceConversionManager: BalanceConversionManager
    private let balanceHiddenManager: BalanceHiddenManager
    private let contactManager: ContactBookManager

    init(accountManager: AccountManager,
         accountFactory: AccountFactory,
         walletManager: WalletManager,
         favoritesManager: FavoritesManager,
         evmSyncSourceManager: EvmSyncSourceManager,
         btcBlockchainManager: BtcBlockchainManager,
         restoreSettingsManager: RestoreSettingsManager,
         chartRepository: ChartIndicatorsRepository,
         localStorage: LocalStorage,
         languageManager: LanguageManager,
         currencyKit: CurrencyKit.Kit,
         themeManager: ThemeManager,
         launchScreenManager: LaunchScreenManager,
         appIconManager: AppIconManager,
         balancePrimaryValueManager: BalancePrimaryValueManager,
         balanceConversionManager: BalanceConversionManager,
         balanceHiddenManager: BalanceHiddenManager,
         contactManager: ContactBookManager)
    {
        self.accountManager = accountManager
        self.accountFactory = accountFactory
        self.walletManager = walletManager
        self.favoritesManager = favoritesManager
        self.evmSyncSourceManager = evmSyncSourceManager
        self.btcBlockchainManager = btcBlockchainManager
        self.restoreSettingsManager = restoreSettingsManager
        self.chartRepository = chartRepository
        self.localStorage = localStorage
        self.languageManager = languageManager
        self.currencyKit = currencyKit
        self.themeManager = themeManager
        self.launchScreenManager = launchScreenManager
        self.appIconManager = appIconManager
        self.balancePrimaryValueManager = balancePrimaryValueManager
        self.balanceConversionManager = balanceConversionManager
        self.balanceHiddenManager = balanceHiddenManager
        self.contactManager = contactManager
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

    private func settings(evmSyncSources: EvmSyncSourceManager.SyncSourceBackup) -> SettingsBackup {
        SettingsBackup(
            evmSyncSources: evmSyncSources,
            btcModes: btcBlockchainManager.backup,
            lockTimeEnabled: localStorage.lockTimeEnabled,
            remoteContactsSync: localStorage.remoteContactsSync,
            swapProviders: swapProviders,
            chartIndicators: chartRepository.backup,
            indicatorsShown: localStorage.indicatorsShown,
            currentLanguage: languageManager.currentLanguage,
            baseCurrency: currencyKit.baseCurrency.code,
            mode: themeManager.themeMode,
            showMarketTab: launchScreenManager.showMarket,
            launchScreen: launchScreenManager.launchScreen,
            conversionTokenQueryId: balanceConversionManager.conversionToken?.tokenQuery.id,
            balancePrimaryValue: balancePrimaryValueManager.balancePrimaryValue,
            balanceAutoHide: balanceHiddenManager.balanceAutoHide,
            appIcon: appIconManager.appIcon.title
        )
    }

    func encrypt(accountIds: [String], passphrase: String) throws -> [RestoreCloudModule.RestoredBackup] {
        try accountIds.compactMap {
            accountManager.account(id: $0)
        }.compactMap {
            let walletBackup = try Self.encrypt(account: $0, wallets: enabledWallets(account: $0), passphrase: passphrase)
            return RestoreCloudModule.RestoredBackup(name: $0.name, walletBackup: walletBackup)
        }
    }

    func fullBackup(accountIds: [String]) -> RawFullBackup {
        let accounts = accountIds
            .compactMap { accountManager.account(id: $0) }
            .compactMap { RawWalletBackup(account: $0, enabledWallets: enabledWallets(account: $0)) }

        let custom = evmSyncSourceManager.customSources
        let selected = evmSyncSourceManager.selectedSources
        let syncSources = EvmSyncSourceManager.SyncSourceBackup(selected: selected, custom: [])
        return RawFullBackup(
            accounts: accounts,
            watchlistIds: favoritesManager.allCoinUids,
            contacts: contactManager.backupContactBook?.contacts ?? [],
            settings: settings(evmSyncSources: syncSources),
            customSyncSources: custom
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

        accountManager.save(accounts: updated.map { $0.account })

        updated.forEach { (raw: RawWalletBackup) in
            switch raw.account.type {
            case .cex: ()
            default:
                let wallets = raw.enabledWallets.compactMap { (wallet: WalletBackup.EnabledWallet) -> EnabledWallet? in
                    guard let tokenQuery = TokenQuery(id: wallet.tokenQueryId),
                        BlockchainType.supported.contains(tokenQuery.blockchainType) else {
                        return nil
                    }

                    if !wallet.settings.isEmpty {
                        var restoreSettings = [RestoreSettingType: String]()
                        wallet.settings.forEach { key, value in
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
    }

    func restore(raw: RawFullBackup) {
        raw.accounts.forEach { wallet in
            restore(raws: [wallet])
        }
        favoritesManager.add(coinUids: raw.watchlistIds)

        if !raw.contacts.isEmpty {
            try? contactManager.restore(contacts: raw.contacts, mergePolitics: .replace)
        }

        evmSyncSourceManager.restore(selected: raw.settings.evmSyncSources.selected, custom: raw.customSyncSources)
        btcBlockchainManager.restore(backup: raw.settings.btcModes)
        chartRepository.restore(backup: raw.settings.chartIndicators)
        localStorage.restore(backup: raw.settings)
        languageManager.currentLanguage = raw.settings.currentLanguage
        if let currency = currencyKit.currencies.first(where: { $0.code == raw.settings.baseCurrency }) {
            currencyKit.baseCurrency = currency
        }

        themeManager.themeMode = raw.settings.mode
        launchScreenManager.showMarket = raw.settings.showMarketTab
        launchScreenManager.launchScreen = raw.settings.launchScreen
        balancePrimaryValueManager.balancePrimaryValue = raw.settings.balancePrimaryValue

        balanceConversionManager.set(tokenQueryId: raw.settings.conversionTokenQueryId)
        balanceHiddenManager.set(balanceAutoHide: raw.settings.balanceAutoHide)
        let appIcon = AppIconManager.allAppIcons.first { $0.title == raw.settings.appIcon } ?? .main
        if appIconManager.appIcon != appIcon {
            appIconManager.appIcon = appIcon
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

        return RawFullBackup(
            accounts: wallets,
            watchlistIds: fullBackup.watchlistIds,
            contacts: contacts ?? [],
            settings: fullBackup.settings,
            customSyncSources: customSources
        )
    }

    func encrypt(raw: RawFullBackup, passphrase: String) throws -> FullBackup {
        let wallets = try raw.accounts.map {
            let walletBackup = try Self.encrypt(account: $0.account, wallets: $0.enabledWallets, passphrase: passphrase)
            return RestoreCloudModule.RestoredBackup(name: $0.account.name, walletBackup: walletBackup)
        }

        let contacts = try ContactBookManager.encrypt(contacts: raw.contacts, passphrase: passphrase)
        let custom = try evmSyncSourceManager.encrypt(sources: raw.customSyncSources, passphrase: passphrase)

        return FullBackup(
            id: UUID().uuidString,
            wallets: wallets,
            watchlistIds: raw.watchlistIds,
            contacts: contacts,
            settings: settings(evmSyncSources: .init(selected: raw.settings.evmSyncSources.selected, custom: custom)),
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

    enum Field {
        static func all(ids: [String]) -> [Self] {
            [.accounts(ids: ids), .watchlist, .contacts, .settings]
        }

        case accounts(ids: [String])
        case watchlist
        case contacts
        case settings
    }
}
