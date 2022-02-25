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

    let marketKit: MarketKit.Kit

    let appConfigProvider: AppConfigProvider

    let localStorage: ILocalStorage & IChartIntervalStorage
    let storage: IEnabledWalletStorage & IAccountRecordStorage & IBlockchainSettingsRecordStorage & ILogRecordStorage & IFavoriteCoinRecordStorage & IWalletConnectSessionStorage& IWalletConnectV2SessionStorage & IActiveAccountStorage & IRestoreSettingsStorage & IAppVersionRecordStorage & IAccountSettingRecordStorage & IEnabledWalletCacheStorage & ICustomTokenStorage & IEvmAccountSyncStateStorage

    let themeManager: ThemeManager
    let systemInfoManager: ISystemInfoManager

    let pasteboardManager: IPasteboardManager
    let reachabilityManager: IReachabilityManager
    let networkManager: NetworkManager

    let wordsManager: IWordsManager

    let accountManager: IAccountManager
    let accountFactory: AccountFactory
    let backupManager: IBackupManager

    let coinManager: CoinManager

    let walletManager: WalletManager
    let adapterManager: AdapterManager
    let transactionAdapterManager: TransactionAdapterManager

    let enabledWalletCacheManager: EnabledWalletCacheManager

    let currencyKit: CurrencyKit.Kit

    let favoritesManager: FavoritesManager

    let feeCoinProvider: FeeCoinProvider
    let feeRateProviderFactory: FeeRateProviderFactory

    let accountSettingManager: AccountSettingManager
    let evmSyncSourceManager: EvmSyncSourceManager
    let evmBlockchainManager: EvmBlockchainManager

    let restoreSettingsManager: RestoreSettingsManager

    private let testModeIndicator: TestModeIndicator

    let logRecordManager: ILogRecordManager & ILogStorage

    var debugLogger: IDebugLogger?
    let logger: Logger

    let appStatusManager: IAppStatusManager
    let appVersionManager: IAppVersionManager

    let initialSyncSettingsManager: InitialSyncSettingsManager

    let transactionDataSortModeSettingManager: ITransactionDataSortModeSettingManager

    let kitCleaner: IKitCleaner

    let keychainKitDelegate: KeychainKitDelegate
    let pinKitDelegate: PinKitDelegate

    let rateAppManager: IRateAppManager
    let guidesManager: IGuidesManager
    let termsManager: ITermsManager

    let walletConnectSessionManager: WalletConnectSessionManager
    let walletConnectV2SessionManager: WalletConnectV2SessionManager
    let walletConnectManager: WalletConnectManager

    let activateCoinManager: ActivateCoinManager

    let deepLinkManager: IDeepLinkManager
    let launchScreenManager: LaunchScreenManager

    let nftManager: NftManager

    let appManager: AppManager

    init() {
        appConfigProvider = AppConfigProvider()

        localStorage = LocalStorage(storage: StorageKit.LocalStorage.default)

        let databaseURL = try! FileManager.default
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("bank.sqlite")
        let dbPool = try! DatabasePool(path: databaseURL.path)
        storage = GrdbStorage(dbPool: dbPool)

        logRecordManager = LogRecordManager(storage: storage)

        marketKit = try! MarketKit.Kit.instance(
                hsApiBaseUrl: appConfigProvider.marketApiUrl,
                cryptoCompareApiKey: appConfigProvider.cryptoCompareApiKey,
                defiYieldApiKey: appConfigProvider.defiYieldApiKey,
                hsProviderApiKey: appConfigProvider.hsProviderApiKey
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

        wordsManager = WordsManager()

        let accountStorage = AccountStorage(secureStorage: keychainKit.secureStorage, storage: storage)
        let accountCachedStorage = AccountCachedStorage(accountStorage: accountStorage, activeAccountStorage: storage)
        accountManager = AccountManager(storage: accountCachedStorage)
        accountFactory = AccountFactory(accountManager: accountManager)
        backupManager = BackupManager(accountManager: accountManager)

        kitCleaner = KitCleaner(accountManager: accountManager)

        coinManager = CoinManager(marketKit: marketKit, storage: storage)

        let walletStorage = WalletStorage(coinManager: coinManager, storage: storage)
        walletManager = WalletManager(accountManager: accountManager, storage: walletStorage)

        accountSettingManager = AccountSettingManager(storage: storage)
        evmSyncSourceManager = EvmSyncSourceManager(appConfigProvider: appConfigProvider, accountSettingManager: accountSettingManager)
        evmBlockchainManager = EvmBlockchainManager(syncSourceManager: evmSyncSourceManager, accountManager: accountManager, walletManager: walletManager, coinManager: coinManager, networkManager: networkManager, storage: storage)

        let binanceKitManager = BinanceKitManager(appConfigProvider: appConfigProvider)

        restoreSettingsManager = RestoreSettingsManager(storage: storage)

        let settingsStorage: IBlockchainSettingsStorage = BlockchainSettingsStorage(storage: storage)
        initialSyncSettingsManager = InitialSyncSettingsManager(marketKit: marketKit, storage: settingsStorage)

        let adapterFactory = AdapterFactory(
                appConfigProvider: appConfigProvider,
                evmBlockchainManager: evmBlockchainManager,
                evmSyncSourceManager: evmSyncSourceManager,
                binanceKitManager: binanceKitManager,
                initialSyncSettingsManager: initialSyncSettingsManager,
                restoreSettingsManager: restoreSettingsManager,
                coinManager: coinManager
        )
        adapterManager = AdapterManager(
                adapterFactory: adapterFactory,
                walletManager: walletManager,
                evmBlockchainManager: evmBlockchainManager,
                initialSyncSettingsManager: initialSyncSettingsManager
        )
        transactionAdapterManager = TransactionAdapterManager(
                adapterManager: adapterManager,
                adapterFactory: adapterFactory
        )

        enabledWalletCacheManager = EnabledWalletCacheManager(storage: storage, accountManager: accountManager)

        currencyKit = CurrencyKit.Kit(localStorage: StorageKit.LocalStorage.default)

        feeCoinProvider = FeeCoinProvider(marketKit: marketKit)
        feeRateProviderFactory = FeeRateProviderFactory(appConfigProvider: appConfigProvider)

        favoritesManager = FavoritesManager(storage: storage)

        transactionDataSortModeSettingManager = TransactionDataSortModeSettingManager(storage: localStorage)

        pinKit = PinKit.Kit(secureStorage: keychainKit.secureStorage, localStorage: StorageKit.LocalStorage.default)
        let blurManager = BlurManager(pinKit: pinKit)

        testModeIndicator = TestModeIndicator(appConfigProvider: appConfigProvider)

        let appVersionStorage: IAppVersionStorage = AppVersionStorage(storage: storage)
        appStatusManager = AppStatusManager(systemInfoManager: systemInfoManager, storage: appVersionStorage, accountManager: accountManager, walletManager: walletManager, adapterManager: adapterManager, logRecordManager: logRecordManager, restoreSettingsManager: restoreSettingsManager)
        appVersionManager = AppVersionManager(systemInfoManager: systemInfoManager, storage: appVersionStorage)

        keychainKitDelegate = KeychainKitDelegate(accountManager: accountManager, walletManager: walletManager)
        keychainKit.set(delegate: keychainKitDelegate)

        pinKitDelegate = PinKitDelegate()
        pinKit.set(delegate: pinKitDelegate)

        rateAppManager = RateAppManager(walletManager: walletManager, adapterManager: adapterManager, localStorage: localStorage)

        guidesManager = GuidesManager(networkManager: networkManager)
        termsManager = TermsManager(storage: StorageKit.LocalStorage.default)

        walletConnectSessionManager = WalletConnectSessionManager(storage: storage, accountManager: accountManager, accountSettingManager: accountSettingManager)
        walletConnectManager = WalletConnectManager(accountManager: accountManager, evmBlockchainManager: evmBlockchainManager)

        let walletClientInfo = WalletConnectClientInfo(
                projectId: appConfigProvider.walletConnectV2ProjectKey ?? "c4f79cc821944d9680842e34466bfb",
                relayHost: "relay.walletconnect.com",
                clientName: "io.horizontalsystems.bank.dev",
                name: "Unstoppable Wallet",
                description: nil,
                url: appConfigProvider.companyWebPageLink,
                icons: []
        )

        let walletConnectV2Service = WalletConnectV2Service(info: walletClientInfo)
        walletConnectV2SessionManager = WalletConnectV2SessionManager(service: walletConnectV2Service, storage: storage, accountManager: accountManager, currentDateProvider: CurrentDateProvider())

        activateCoinManager = ActivateCoinManager(marketKit: marketKit, walletManager: walletManager, accountManager: accountManager)

        deepLinkManager = DeepLinkManager()
        launchScreenManager = LaunchScreenManager(storage: StorageKit.LocalStorage.default)

        let nftDatabaseStorage = try! NftDatabaseStorage(dbPool: dbPool)
        let nftStorage = NftStorage(marketKit: marketKit, storage: nftDatabaseStorage)
        let nftProvider = HsNftProvider(networkManager: networkManager, marketKit: marketKit, appConfigProvider: appConfigProvider)
        nftManager = NftManager(accountManager: accountManager, evmBlockchainManager: evmBlockchainManager, storage: nftStorage, provider: nftProvider)

        let restoreCustomTokenWorker = RestoreCustomTokenWorker(
                coinManager: coinManager,
                walletManager: walletManager,
                storage: storage,
                localStorage: StorageKit.LocalStorage.default,
                networkManager: networkManager
        )

        let restoreFavoriteCoinWorker = RestoreFavoriteCoinWorker(
                coinManager: coinManager,
                favoritesManager: favoritesManager,
                localStorage: StorageKit.LocalStorage.default,
                storage: storage
        )

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
                restoreCustomTokenWorker: restoreCustomTokenWorker,
                restoreFavoriteCoinWorker: restoreFavoriteCoinWorker
        )
    }

}
