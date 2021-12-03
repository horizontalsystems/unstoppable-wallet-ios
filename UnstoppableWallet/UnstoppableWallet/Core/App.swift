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

    let localStorage: ILocalStorage & IChartTypeStorage
    let storage: IEnabledWalletStorage & IAccountRecordStorage & IBlockchainSettingsRecordStorage & ILogRecordStorage & IFavoriteCoinRecordStorage & IWalletConnectSessionStorage & IActiveAccountStorage & IRestoreSettingsStorage & IAppVersionRecordStorage & IAccountSettingRecordStorage & IEnabledWalletCacheStorage & ICustomTokenStorage

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

    let evmNetworkManager: EvmNetworkManager
    let accountSettingManager: AccountSettingManager

    let ethereumKitManager: EvmKitManager
    let binanceSmartChainKitManager: EvmKitManager

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
    let walletConnectManager: WalletConnectManager

    let activateCoinManager: ActivateCoinManager

    let deepLinkManager: IDeepLinkManager
    let launchScreenManager: LaunchScreenManager

    let appManager: AppManager

    init() {
        appConfigProvider = AppConfigProvider()

        localStorage = LocalStorage(storage: StorageKit.LocalStorage.default)
        storage = GrdbStorage()
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

        evmNetworkManager = EvmNetworkManager(appConfigProvider: appConfigProvider)
        accountSettingManager = AccountSettingManager(storage: storage, evmNetworkManager: evmNetworkManager)

        let ethereumDataSource = EthKitManagerDataSource(appConfigProvider: appConfigProvider, accountSettingManager: accountSettingManager)
        let binanceSmartChainDataSource = BscKitManagerDataSource(appConfigProvider: appConfigProvider, accountSettingManager: accountSettingManager)

        ethereumKitManager = EvmKitManager(dataSource: ethereumDataSource)
        binanceSmartChainKitManager = EvmKitManager(dataSource: binanceSmartChainDataSource)

        let binanceKitManager = BinanceKitManager(appConfigProvider: appConfigProvider)

        restoreSettingsManager = RestoreSettingsManager(storage: storage)

        let settingsStorage: IBlockchainSettingsStorage = BlockchainSettingsStorage(storage: storage)
        initialSyncSettingsManager = InitialSyncSettingsManager(marketKit: marketKit, storage: settingsStorage)

        let walletStorage = WalletStorage(coinManager: coinManager, storage: storage)

        walletManager = WalletManager(accountManager: accountManager, storage: walletStorage)

        let adapterFactory = AdapterFactory(
                appConfigProvider: appConfigProvider,
                ethereumKitManager: ethereumKitManager,
                binanceSmartChainKitManager: binanceSmartChainKitManager,
                binanceKitManager: binanceKitManager,
                initialSyncSettingsManager: initialSyncSettingsManager,
                restoreSettingsManager: restoreSettingsManager,
                coinManager: coinManager
        )
        adapterManager = AdapterManager(
                adapterFactory: adapterFactory,
                walletManager: walletManager,
                ethereumKitManager: ethereumKitManager,
                binanceSmartChainKitManager: binanceSmartChainKitManager,
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
        let blurManager: IBlurManager = BlurManager(pinKit: pinKit)

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
        walletConnectManager = WalletConnectManager(accountManager: accountManager, ethereumKitManager: ethereumKitManager, binanceSmartChainKitManager: binanceSmartChainKitManager)

        activateCoinManager = ActivateCoinManager(marketKit: marketKit, walletManager: walletManager, accountManager: accountManager)

        deepLinkManager = DeepLinkManager()
        launchScreenManager = LaunchScreenManager(storage: StorageKit.LocalStorage.default)

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
