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

    private func walletBackups(ids: [String], passphrase: String) -> [RestoreCloudModule.RestoredBackup] {
        ids.compactMap {
            accountManager.account(id: $0)
        }.compactMap {
            try? walletBackup(account: $0, passphrase: passphrase)
        }
    }
}

extension AppBackupProvider {
    func walletBackup(account: Account, passphrase: String) throws -> RestoreCloudModule.RestoredBackup {
        let wallets = App.shared
            .walletManager
            .wallets(account: account).map {
                let settings = restoreSettingsManager
                    .settings(accountId: account.id, blockchainType: $0.token.blockchainType)
                    .reduce(into: [:]) { $0[$1.0.rawValue] = $1.1 }

                return WalletBackup.EnabledWallet($0, settings: settings)
            }
        return try AppBackupProvider.walletBackup(
            accountType: account.type,
            wallets: wallets,
            isManualBackedUp: account.backedUp,
            name: account.name,
            passphrase: passphrase
        )
    }

    func fullBackup(fields: [Field], passphrase: String) throws -> FullBackup {
        var wallets = [RestoreCloudModule.RestoredBackup]()
        var watchlistIds = [String]()
        var contacts = [BackupContact]()
        var settings: SettingsBackup?
        for field in fields {
            switch field {
            case let .accounts(ids):
                wallets.append(contentsOf: walletBackups(ids: ids, passphrase: passphrase))
            case .watchlist:
                watchlistIds = favoritesManager.allCoinUids
            case .contacts:
                contacts = contactManager.backupContactBook?.contacts ?? []
            case .settings:
                let providers: [SettingsBackup.DefaultProvider] = BlockchainType
                    .supported
                    .filter { !$0.allowedProviders.isEmpty }
                    .map {
                        SettingsBackup.DefaultProvider(
                            blockchainTypeId: $0.uid,
                            provider: localStorage.defaultProvider(blockchainType: $0).id
                        )
                    }
                settings = SettingsBackup(
                    evmSyncSources: evmSyncSourceManager.backup(passphrase: passphrase),
                    btcModes: btcBlockchainManager.backup,
                    lockTimeEnabled: localStorage.lockTimeEnabled,
                    remoteContactsSync: localStorage.remoteContactsSync,
                    swapProviders: providers,
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
        }

        guard !wallets.isEmpty ||
            !watchlistIds.isEmpty ||
            !contacts.isEmpty ||
            settings != nil
        else {
            throw CodingError.emptyParameters
        }

        var contactCrypto: BackupCrypto?
        if !contacts.isEmpty {
            let encoder = JSONEncoder()
            let data = try encoder.encode(contacts)
            contactCrypto = try BackupCrypto.instance(data: data, passphrase: passphrase)
        }

        return FullBackup(
            id: UUID().uuidString,
            wallets: wallets,
            watchlistIds: watchlistIds,
            contacts: contactCrypto,
            settings: settings,
            version: AppBackupProvider.version,
            timestamp: Date().timeIntervalSince1970.rounded()
        )
    }

    func walletRestore(backup: RestoreCloudModule.RestoredBackup, accountType: AccountType) {
        switch accountType {
        case .cex:
            let account = accountFactory.account(
                type: accountType,
                origin: .restored,
                backedUp: backup.walletBackup.isManualBackedUp,
                name: backup.name
            )
            accountManager.save(account: account)
        default:
            let account = accountFactory.account(type: accountType, origin: .restored, backedUp: backup.walletBackup.isManualBackedUp, name: backup.name)
            accountManager.save(account: account)

            let wallets = backup.walletBackup.enabledWallets.map {
                if !$0.settings.isEmpty {
                    var restoreSettings = [RestoreSettingType: String]()
                    $0.settings.forEach { key, value in
                        if let key = RestoreSettingType(rawValue: key) {
                            restoreSettings[key] = value
                        }
                    }
                    if let tokenQuery = TokenQuery(id: $0.tokenQueryId) {
                        restoreSettingsManager.save(settings: restoreSettings, account: account, blockchainType: tokenQuery.blockchainType)
                    }
                }
                return EnabledWallet(
                    tokenQueryId: $0.tokenQueryId,
                    accountId: account.id,
                    coinName: $0.coinName,
                    coinCode: $0.coinCode,
                    tokenDecimals: $0.tokenDecimals
                )
            }
            walletManager.save(enabledWallets: wallets)
        }
    }

    func fullRestore(backup: FullBackup, passphrase: String) throws {
        var encryptionError: Error?
        var encodedWallets = [(RestoreCloudModule.RestoredBackup, AccountType)]()
        backup.wallets.forEach { wallet in
            do {
                let accountType = try wallet
                    .walletBackup
                    .crypto
                    .accountType(type: wallet.walletBackup.type, passphrase: passphrase)
                encodedWallets.append((wallet, accountType))
            } catch {
                encryptionError = error
            }
        }

        if encodedWallets.count != backup.wallets.count {
            encryptionError = CodingError.invalidPassword
        }

        if let encryptionError {
            throw encryptionError
        }
        // restore only if all wallet was encrypted with password
        encodedWallets.forEach { wallet in
            walletRestore(
                backup: wallet.0,
                accountType: wallet.1
            )
        }

        favoritesManager.add(coinUids: backup.watchlistIds)

        if let contacts = backup.contacts {
            try contactManager.restore(crypto: contacts, passphrase: passphrase)
        }

        if let settings = backup.settings {
            evmSyncSourceManager.restore(backup: settings.evmSyncSources)
            btcBlockchainManager.restore(backup: settings.btcModes)
            chartRepository.restore(backup: settings.chartIndicators)
            localStorage.restore(backup: settings)
            languageManager.currentLanguage = settings.currentLanguage
            if let currency = currencyKit.currencies.first(where: { $0.code == settings.baseCurrency }) {
                currencyKit.baseCurrency = currency
            }
            themeManager.themeMode = settings.mode
            launchScreenManager.showMarket = settings.showMarketTab
            launchScreenManager.launchScreen = settings.launchScreen

            balanceConversionManager.set(tokenQueryId: settings.conversionTokenQueryId)
            balanceHiddenManager.set(balanceAutoHide: settings.balanceAutoHide)
            let appIcon = AppIconManager.allAppIcons.first { $0.title == settings.appIcon } ?? .main
            if appIconManager.appIcon != appIcon {
                appIconManager.appIcon = appIcon
            }
        }
    }
}

extension AppBackupProvider {
    static func walletBackup(accountType: AccountType, wallets: [WalletBackup.EnabledWallet], isManualBackedUp: Bool, name: String, passphrase: String) throws -> RestoreCloudModule.RestoredBackup {
        let message = accountType.uniqueId(hashed: false)
        let crypto = try BackupCrypto.instance(data: message, passphrase: passphrase)

        let walletBackup = WalletBackup(
            crypto: crypto,
            enabledWallets: wallets,
            id: accountType.uniqueId().hs.hex,
            type: AccountType.Abstract(accountType),
            isManualBackedUp: isManualBackedUp,
            version: Self.version,
            timestamp: Date().timeIntervalSince1970.rounded()
        )

        return .init(name: name, walletBackup: walletBackup)
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
