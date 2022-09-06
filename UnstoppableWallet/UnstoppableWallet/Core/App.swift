import Foundation
import GRDB
import ThemeKit
import StorageKit
import PinKit
import CurrencyKit
import HsToolKit
import MarketKit

class App {
    static let shared = App()

    let keychainKit: IKeychainKit
    let pinKit: IPinKit

    let currencyKit: CurrencyKit.Kit

    let marketKit: MarketKit.Kit

    let appConfigProvider: AppConfigProvider

    let localStorage: LocalStorage

    let themeManager: ThemeManager
    let systemInfoManager: SystemInfoManager

    let pasteboardManager: PasteboardManager
    let reachabilityManager: IReachabilityManager
    let networkManager: NetworkManager

    let accountManager: AccountManager
    let accountFactory: AccountFactory
    let backupManager: BackupManager

    let coinManager: CoinManager

    let evmLabelManager: EvmLabelManager

    let walletManager: WalletManager
    let adapterManager: AdapterManager
    let transactionAdapterManager: TransactionAdapterManager
    let watchAddressBlockchainManager: WatchAddressBlockchainManager

    let nftMetadataManager: NftMetadataManager
    let nftAdapterManager: NftAdapterManager
    let nftMetadataSyncer: NftMetadataSyncer

    let enabledWalletCacheManager: EnabledWalletCacheManager

    let favoritesManager: FavoritesManager

    let feeCoinProvider: FeeCoinProvider
    let feeRateProviderFactory: FeeRateProviderFactory

    let evmSyncSourceManager: EvmSyncSourceManager
    let evmAccountRestoreStateManager: EvmAccountRestoreStateManager
    let evmBlockchainManager: EvmBlockchainManager

    let restoreSettingsManager: RestoreSettingsManager
    let predefinedBlockchainService: PredefinedBlockchainService

    private let testModeIndicator: TestModeIndicator

    let logRecordManager: LogRecordManager

    var debugLogger: DebugLogger?
    let logger: Logger

    let appStatusManager: AppStatusManager
    let appVersionManager: AppVersionManager

    let btcBlockchainManager: BtcBlockchainManager

    let kitCleaner: KitCleaner

    let keychainKitDelegate: KeychainKitDelegate
    let pinKitDelegate: PinKitDelegate

    let rateAppManager: RateAppManager
    let guidesManager: GuidesManager
    let termsManager: TermsManager

    let walletConnectSessionManager: WalletConnectSessionManager
    let walletConnectV2SocketConnectionService: WalletConnectV2SocketConnectionService
    let walletConnectV2SessionManager: WalletConnectV2SessionManager
    let walletConnectManager: WalletConnectManager

    let deepLinkManager: DeepLinkManager
    let launchScreenManager: LaunchScreenManager

    let balancePrimaryValueManager: BalancePrimaryValueManager
    let balanceHiddenManager: BalanceHiddenManager
    let balanceConversionManager: BalanceConversionManager

    let appIconManager = AppIconManager()

    let proFeaturesAuthorizationAdapter: ProFeaturesAuthorizationAdapter
    let proFeaturesAuthorizationManager: ProFeaturesAuthorizationManager

    let appManager: AppManager

    init() {
        appConfigProvider = AppConfigProvider()

        localStorage = LocalStorage(storage: StorageKit.LocalStorage.default)

        let databaseURL = try! FileManager.default
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("bank.sqlite")
        let dbPool = try! DatabasePool(path: databaseURL.path)

        try! StorageMigrator.migrate(dbPool: dbPool)

        let logRecordStorage = LogRecordStorage(dbPool: dbPool)
        logRecordManager = LogRecordManager(storage: logRecordStorage)

        currencyKit = CurrencyKit.Kit(localStorage: StorageKit.LocalStorage.default)

        marketKit = try! MarketKit.Kit.instance(
                hsApiBaseUrl: appConfigProvider.marketApiUrl,
                cryptoCompareApiKey: appConfigProvider.cryptoCompareApiKey,
                defiYieldApiKey: appConfigProvider.defiYieldApiKey,
                hsProviderApiKey: appConfigProvider.hsProviderApiKey,
                minLogLevel: .error
        )
        marketKit.sync()

        logger = Logger(minLogLevel: .error, storage: logRecordManager)
        networkManager = NetworkManager(logger: logger)

        keychainKit = KeychainKit(service: "io.horizontalsystems.bank.dev")

        themeManager = ThemeManager.shared
        systemInfoManager = SystemInfoManager()

        if appConfigProvider.officeMode {
            debugLogger = DebugLogger(localStorage: localStorage, dateProvider: CurrentDateProvider())
        }

        pasteboardManager = PasteboardManager()
        reachabilityManager = ReachabilityManager()

        let accountRecordStorage = AccountRecordStorage(dbPool: dbPool)
        let accountStorage = AccountStorage(secureStorage: keychainKit.secureStorage, storage: accountRecordStorage)
        let activeAccountStorage = ActiveAccountStorage(dbPool: dbPool)
        let accountCachedStorage = AccountCachedStorage(accountStorage: accountStorage, activeAccountStorage: activeAccountStorage)
        accountManager = AccountManager(storage: accountCachedStorage)
        accountFactory = AccountFactory(accountManager: accountManager)
        backupManager = BackupManager(accountManager: accountManager)

        kitCleaner = KitCleaner(accountManager: accountManager)

        let enabledWalletStorage = EnabledWalletStorage(dbPool: dbPool)
        let walletStorage = WalletStorage(marketKit: marketKit, storage: enabledWalletStorage)
        walletManager = WalletManager(accountManager: accountManager, storage: walletStorage)

        coinManager = CoinManager(marketKit: marketKit, walletManager: walletManager)

        let blockchainSettingRecordStorage = try! BlockchainSettingRecordStorage(dbPool: dbPool)
        let blockchainSettingsStorage = BlockchainSettingsStorage(storage: blockchainSettingRecordStorage)
        btcBlockchainManager = BtcBlockchainManager(marketKit: marketKit, storage: blockchainSettingsStorage)

        evmSyncSourceManager = EvmSyncSourceManager(appConfigProvider: appConfigProvider, storage: blockchainSettingsStorage)

        let evmAccountRestoreStateStorage = EvmAccountRestoreStateStorage(dbPool: dbPool)
        evmAccountRestoreStateManager = EvmAccountRestoreStateManager(storage: evmAccountRestoreStateStorage)

        let evmAccountManagerFactory = EvmAccountManagerFactory(accountManager: accountManager, walletManager: walletManager, evmAccountRestoreStateManager: evmAccountRestoreStateManager, marketKit: marketKit)
        evmBlockchainManager = EvmBlockchainManager(syncSourceManager: evmSyncSourceManager, marketKit: marketKit, accountManagerFactory: evmAccountManagerFactory)

        let binanceKitManager = BinanceKitManager(appConfigProvider: appConfigProvider)

        let restoreSettingsStorage = RestoreSettingsStorage(dbPool: dbPool)
        restoreSettingsManager = RestoreSettingsManager(storage: restoreSettingsStorage)
        predefinedBlockchainService = PredefinedBlockchainService(restoreSettingsManager: restoreSettingsManager)

        let hsLabelProvider = HsLabelProvider(networkManager: networkManager, appConfigProvider: appConfigProvider)
        let evmLabelStorage = EvmLabelStorage(dbPool: dbPool)
        let syncerStateStorage = SyncerStateStorage(dbPool: dbPool)
        evmLabelManager = EvmLabelManager(provider: hsLabelProvider, storage: evmLabelStorage, syncerStateStorage: syncerStateStorage)

        let adapterFactory = AdapterFactory(
                appConfigProvider: appConfigProvider,
                evmBlockchainManager: evmBlockchainManager,
                evmSyncSourceManager: evmSyncSourceManager,
                binanceKitManager: binanceKitManager,
                btcBlockchainManager: btcBlockchainManager,
                restoreSettingsManager: restoreSettingsManager,
                coinManager: coinManager,
                evmLabelManager: evmLabelManager
        )
        adapterManager = AdapterManager(
                adapterFactory: adapterFactory,
                walletManager: walletManager,
                evmBlockchainManager: evmBlockchainManager,
                btcBlockchainManager: btcBlockchainManager
        )
        transactionAdapterManager = TransactionAdapterManager(
                adapterManager: adapterManager,
                evmBlockchainManager: evmBlockchainManager,
                adapterFactory: adapterFactory
        )
        watchAddressBlockchainManager = WatchAddressBlockchainManager(
                marketKit: marketKit,
                walletManager: walletManager,
                accountManager: accountManager,
                evmBlockchainManager: evmBlockchainManager
        )

        let nftDatabaseStorage = try! NftDatabaseStorage(dbPool: dbPool)
        let nftStorage = NftStorage(marketKit: marketKit, storage: nftDatabaseStorage)
        nftMetadataManager = NftMetadataManager(networkManager: networkManager, marketKit: marketKit, appConfigProvider: appConfigProvider, storage: nftStorage)
        nftAdapterManager = NftAdapterManager(
                walletManager: walletManager,
                evmBlockchainManager: evmBlockchainManager
        )
        nftMetadataSyncer = NftMetadataSyncer(nftAdapterManager: nftAdapterManager, nftMetadataManager: nftMetadataManager, nftStorage: nftStorage)

        let enabledWalletCacheStorage = EnabledWalletCacheStorage(dbPool: dbPool)
        enabledWalletCacheManager = EnabledWalletCacheManager(storage: enabledWalletCacheStorage, accountManager: accountManager)

        feeCoinProvider = FeeCoinProvider(marketKit: marketKit)
        feeRateProviderFactory = FeeRateProviderFactory(appConfigProvider: appConfigProvider)

        let favoriteCoinRecordStorage = FavoriteCoinRecordStorage(dbPool: dbPool)
        favoritesManager = FavoritesManager(storage: favoriteCoinRecordStorage)

        pinKit = PinKit.Kit(secureStorage: keychainKit.secureStorage, localStorage: StorageKit.LocalStorage.default)
        let blurManager = BlurManager(pinKit: pinKit)

        testModeIndicator = TestModeIndicator(appConfigProvider: appConfigProvider)

        let appVersionRecordStorage = AppVersionRecordStorage(dbPool: dbPool)
        let appVersionStorage = AppVersionStorage(storage: appVersionRecordStorage)

        appStatusManager = AppStatusManager(
                systemInfoManager: systemInfoManager,
                storage: appVersionStorage,
                accountManager: accountManager,
                walletManager: walletManager,
                adapterManager: adapterManager,
                logRecordManager: logRecordManager,
                restoreSettingsManager: restoreSettingsManager,
                evmBlockchainManager: evmBlockchainManager,
                binanceKitManager: binanceKitManager,
                marketKit: marketKit
        )

        appVersionManager = AppVersionManager(systemInfoManager: systemInfoManager, storage: appVersionStorage)

        keychainKitDelegate = KeychainKitDelegate(accountManager: accountManager, walletManager: walletManager)
        keychainKit.set(delegate: keychainKitDelegate)

        pinKitDelegate = PinKitDelegate()
        pinKit.set(delegate: pinKitDelegate)

        rateAppManager = RateAppManager(walletManager: walletManager, adapterManager: adapterManager, localStorage: localStorage)

        guidesManager = GuidesManager(networkManager: networkManager)
        termsManager = TermsManager(storage: StorageKit.LocalStorage.default)

        let walletConnectSessionStorage = WalletConnectSessionStorage(dbPool: dbPool)
        walletConnectSessionManager = WalletConnectSessionManager(storage: walletConnectSessionStorage, accountManager: accountManager)
        walletConnectManager = WalletConnectManager(accountManager: accountManager, evmBlockchainManager: evmBlockchainManager)

        let walletClientInfo = WalletConnectClientInfo(
                projectId: appConfigProvider.walletConnectV2ProjectKey ?? "c4f79cc821944d9680842e34466bfb",
                relayHost: "relay.walletconnect.com",
                name: "Unstoppable Wallet",
                description: "Wallet App",
                url: appConfigProvider.companyWebPageLink,
                icons: []
        )

        walletConnectV2SocketConnectionService = WalletConnectV2SocketConnectionService(reachabilityManager: reachabilityManager, logger: logger)
        let walletConnectV2Service = WalletConnectV2Service(
                connectionService: walletConnectV2SocketConnectionService,
                info: walletClientInfo,
                logger: logger
        )
        let walletConnectV2SessionStorage = WalletConnectV2SessionStorage(dbPool: dbPool)
        walletConnectV2SessionManager = WalletConnectV2SessionManager(service: walletConnectV2Service, storage: walletConnectV2SessionStorage, accountManager: accountManager, currentDateProvider: CurrentDateProvider())

        deepLinkManager = DeepLinkManager()
        launchScreenManager = LaunchScreenManager(storage: StorageKit.LocalStorage.default)

        balancePrimaryValueManager = BalancePrimaryValueManager(localStorage: StorageKit.LocalStorage.default)
        balanceHiddenManager = BalanceHiddenManager(localStorage: StorageKit.LocalStorage.default)
        balanceConversionManager = BalanceConversionManager(marketKit: marketKit, localStorage: StorageKit.LocalStorage.default)

        let proFeaturesStorage = ProFeaturesStorage(secureStorage: keychainKit.secureStorage)
        proFeaturesAuthorizationAdapter = ProFeaturesAuthorizationAdapter(networkManager: networkManager, appConfigProvider: appConfigProvider)
        proFeaturesAuthorizationManager = ProFeaturesAuthorizationManager(storage: proFeaturesStorage, accountManager: accountManager, evmSyncSourceManager: evmSyncSourceManager)

        appManager = AppManager(
                accountManager: accountManager,
                walletManager: walletManager,
                adapterManager: adapterManager,
                pinKit: pinKit,
                keychainKit: keychainKit,
                blurManager: blurManager,
                kitCleaner: kitCleaner,
                debugLogger: debugLogger,
                appVersionManager: appVersionManager,
                rateAppManager: rateAppManager,
                logRecordManager: logRecordManager,
                deepLinkManager: deepLinkManager,
                evmLabelManager: evmLabelManager,
                walletConnectV2SocketConnectionService: walletConnectV2SocketConnectionService,
                nftMetadataSyncer: nftMetadataSyncer
        )
    }

}
