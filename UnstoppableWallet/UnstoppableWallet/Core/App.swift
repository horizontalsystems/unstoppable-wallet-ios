import ThemeKit
import StorageKit
import PinKit
import CurrencyKit
import HsToolKit
import CoinKit

class App {
    static let shared = App()

    let keychainKit: IKeychainKit
    let pinKit: IPinKit

    let coinKit: CoinKit.Kit

    let appConfigProvider: IAppConfigProvider

    let localStorage: ILocalStorage & IChartTypeStorage
    let storage: ICoinMigration & IEnabledWalletStorage & IAccountRecordStorage & IPriceAlertRecordStorage & IBlockchainSettingsRecordStorage & IPriceAlertRequestRecordStorage & ILogRecordStorage & IFavoriteCoinRecordStorage & IWalletConnectSessionStorage & IActiveAccountStorage & IRestoreSettingsStorage & IAppVersionRecordStorage & IAccountSettingRecordStorage & IEnabledWalletCacheStorage

    let themeManager: ThemeManager
    let systemInfoManager: ISystemInfoManager

    let pasteboardManager: IPasteboardManager
    let reachabilityManager: IReachabilityManager
    let networkManager: NetworkManager

    let wordsManager: IWordsManager

    let accountManager: IAccountManager
    let accountFactory: AccountFactory
    let backupManager: IBackupManager

    let coinManager: ICoinManager

    let walletManager: WalletManager
    let adapterManager: AdapterManager

    let enabledWalletCacheManager: EnabledWalletCacheManager

    let currencyKit: CurrencyKit.Kit

    let rateManager: IRateManager & IPostsManager
    let favoritesManager: IFavoritesManager

    let feeCoinProvider: IFeeCoinProvider
    let feeRateProviderFactory: FeeRateProviderFactory

    let sortTypeManager: ISortTypeManager

    let evmNetworkManager: EvmNetworkManager
    let accountSettingManager: AccountSettingManager

    let ethereumKitManager: EvmKitManager
    let binanceSmartChainKitManager: EvmKitManager

    let restoreSettingsManager: RestoreSettingsManager

    private let testModeIndicator: TestModeIndicator

    var remoteAlertManager: IRemoteAlertManager
    let priceAlertManager: IPriceAlertManager
    let notificationManager: INotificationManager
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

    let appManager: AppManager

    init() {
        appConfigProvider = AppConfigProvider()

        localStorage = LocalStorage(storage: StorageKit.LocalStorage.default)
        storage = GrdbStorage(appConfigProvider: appConfigProvider)
        logRecordManager = LogRecordManager(storage: storage)

        coinKit = try! CoinKit.Kit.instance(testNet: appConfigProvider.testMode)
        coinKit.coinMigrationObservable = storage.coinMigrationObservable

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

        coinManager = CoinManager(appConfigProvider: appConfigProvider, coinKit: coinKit)

        evmNetworkManager = EvmNetworkManager(appConfigProvider: appConfigProvider)
        accountSettingManager = AccountSettingManager(storage: storage, evmNetworkManager: evmNetworkManager)

        let ethereumDataSource = EthKitManagerDataSource(appConfigProvider: appConfigProvider, accountSettingManager: accountSettingManager)
        let binanceSmartChainDataSource = BscKitManagerDataSource(appConfigProvider: appConfigProvider, accountSettingManager: accountSettingManager)

        ethereumKitManager = EvmKitManager(dataSource: ethereumDataSource)
        binanceSmartChainKitManager = EvmKitManager(dataSource: binanceSmartChainDataSource)

        let binanceKitManager = BinanceKitManager(appConfigProvider: appConfigProvider)

        restoreSettingsManager = RestoreSettingsManager(storage: storage)

        let settingsStorage: IBlockchainSettingsStorage = BlockchainSettingsStorage(storage: storage)
        initialSyncSettingsManager = InitialSyncSettingsManager(coinKit: coinKit, storage: settingsStorage)

        let walletStorage: IWalletStorage = WalletStorage(coinManager: coinManager, storage: storage)
        let adapterProviderFactory = AdapterFactory(appConfigProvider: appConfigProvider, ethereumKitManager: ethereumKitManager, binanceSmartChainKitManager: binanceSmartChainKitManager, binanceKitManager: binanceKitManager, initialSyncSettingsManager: initialSyncSettingsManager, restoreSettingsManager: restoreSettingsManager, coinManager: coinManager)

        walletManager = WalletManager(accountManager: accountManager, adapterProviderFactory: adapterProviderFactory, storage: walletStorage)

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

        enabledWalletCacheManager = EnabledWalletCacheManager(storage: storage, accountManager: accountManager)

        currencyKit = CurrencyKit.Kit(localStorage: StorageKit.LocalStorage.default)

        feeCoinProvider = FeeCoinProvider(coinKit: coinKit)
        feeRateProviderFactory = FeeRateProviderFactory(appConfigProvider: appConfigProvider)

        rateManager = RateManager(walletManager: walletManager, currencyKit: currencyKit, rateCoinMapper: RateCoinMapper(), feeCoinProvider: feeCoinProvider, appConfigProvider: appConfigProvider)
        favoritesManager = FavoritesManager(storage: storage)

        sortTypeManager = SortTypeManager(localStorage: localStorage)

        transactionDataSortModeSettingManager = TransactionDataSortModeSettingManager(storage: localStorage)

        pinKit = PinKit.Kit(secureStorage: keychainKit.secureStorage, localStorage: StorageKit.LocalStorage.default)
        let blurManager: IBlurManager = BlurManager(pinKit: pinKit)

        testModeIndicator = TestModeIndicator(appConfigProvider: appConfigProvider)

        let priceAlertRequestStorage: IPriceAlertRequestStorage = PriceAlertRequestStorage(storage: storage)
        remoteAlertManager = RemoteAlertManager(networkManager: networkManager, reachabilityManager: reachabilityManager, appConfigProvider: appConfigProvider, jsonSerializer: JsonSerializer(), storage: priceAlertRequestStorage)

        let serializer = JsonSerializer()
        let priceAlertStorage: IPriceAlertStorage = PriceAlertStorage(storage: storage)
        priceAlertManager = PriceAlertManager(walletManager: walletManager, remoteAlertManager: remoteAlertManager, rateManager: rateManager, storage: priceAlertStorage, localStorage: localStorage, serializer: serializer)

        notificationManager = NotificationManager(priceAlertManager: priceAlertManager, remoteAlertManager: remoteAlertManager, rateManager: rateManager, storage: localStorage, serializer: serializer)

        remoteAlertManager.notificationManager = notificationManager

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

        activateCoinManager = ActivateCoinManager(coinKit: coinKit, walletManager: walletManager, accountManager: accountManager)

        deepLinkManager = DeepLinkManager()

        appManager = AppManager(
                accountManager: accountManager,
                walletManager: walletManager,
                adapterManager: adapterManager,
                pinKit: pinKit,
                keychainKit: keychainKit,
                blurManager: blurManager,
                notificationManager: notificationManager,
                kitCleaner: kitCleaner,
                debugLogger: debugLogger,
                appVersionManager: appVersionManager,
                rateAppManager: rateAppManager,
                remoteAlertManager: remoteAlertManager,
                logRecordManager: logRecordManager,
                deepLinkManager: deepLinkManager
        )
    }

}
