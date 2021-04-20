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
    let storage: ICoinMigration & IEnabledWalletStorage & IAccountRecordStorage & IPriceAlertRecordStorage & IBlockchainSettingsRecordStorage & IPriceAlertRequestRecordStorage & ILogRecordStorage & IFavoriteCoinRecordStorage & IWalletConnectSessionStorage & IActiveAccountStorage & IRestoreSettingsStorage & IAppVersionRecordStorage

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

    let walletManager: IWalletManager

    let currencyKit: ICurrencyKit

    let rateManager: IRateManager & IPostsManager
    let favoritesManager: IFavoritesManager

    let feeCoinProvider: IFeeCoinProvider
    let feeRateProviderFactory: FeeRateProviderFactory

    let sortTypeManager: ISortTypeManager

    let restoreSettingsManager: RestoreSettingsManager
    let adapterManager: IAdapterManager

    private let testModeIndicator: TestModeIndicator
    private let walletRemover: WalletRemover

    var remoteAlertManager: IRemoteAlertManager
    let priceAlertManager: IPriceAlertManager
    let notificationManager: INotificationManager
    let logRecordManager: ILogRecordManager & ILogStorage

    var debugLogger: IDebugLogger?
    let logger: Logger

    let appStatusManager: IAppStatusManager
    let appVersionManager: IAppVersionManager

    let initialSyncSettingsManager: IInitialSyncSettingsManager
    let ethereumRpcModeSettingsManager: IEthereumRpcModeSettingsManager

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

    let appManager: AppManager
    let ethereumKitManager: EthereumKitManager
    let binanceSmartChainKitManager: BinanceSmartChainKitManager

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

        let accountStorage: IAccountStorage = AccountStorage(secureStorage: keychainKit.secureStorage, storage: storage)
        accountManager = AccountManager(storage: accountStorage, activeAccountStorage: storage)
        accountFactory = AccountFactory(accountManager: accountManager)
        backupManager = BackupManager(accountManager: accountManager)

        kitCleaner = KitCleaner(accountManager: accountManager)

        coinManager = CoinManager(appConfigProvider: appConfigProvider, coinKit: coinKit)

        let walletStorage: IWalletStorage = WalletStorage(coinManager: coinManager, storage: storage)
        walletManager = WalletManager(accountManager: accountManager, storage: walletStorage, kitCleaner: kitCleaner)

        currencyKit = CurrencyKit.Kit(localStorage: StorageKit.LocalStorage.default, currencyCodes: appConfigProvider.currencyCodes)

        feeCoinProvider = FeeCoinProvider(coinKit: coinKit)
        feeRateProviderFactory = FeeRateProviderFactory(appConfigProvider: appConfigProvider)

        rateManager = RateManager(walletManager: walletManager, currencyKit: currencyKit, rateCoinMapper: RateCoinMapper(), feeCoinProvider: feeCoinProvider, coinMarketCapApiKey: appConfigProvider.coinMarketCapApiKey, cryptoCompareApiKey: appConfigProvider.cryptoCompareApiKey, uniswapSubgraphUrl: appConfigProvider.uniswapSubgraphUrl)
        favoritesManager = FavoritesManager(storage: storage)

        sortTypeManager = SortTypeManager(localStorage: localStorage)

        ethereumKitManager = EthereumKitManager(appConfigProvider: appConfigProvider)
        binanceSmartChainKitManager = BinanceSmartChainKitManager(appConfigProvider: appConfigProvider)
        let binanceKitManager = BinanceKitManager(appConfigProvider: appConfigProvider)

        restoreSettingsManager = RestoreSettingsManager(storage: storage)

        let adapterFactory = AdapterFactory(appConfigProvider: appConfigProvider, ethereumKitManager: ethereumKitManager, binanceSmartChainKitManager: binanceSmartChainKitManager, binanceKitManager: binanceKitManager, restoreSettingsManager: restoreSettingsManager)
        adapterManager = AdapterManager(adapterFactory: adapterFactory, ethereumKitManager: ethereumKitManager, binanceSmartChainKitManager: binanceSmartChainKitManager, binanceKitManager: binanceKitManager, walletManager: walletManager)

        let settingsStorage: IBlockchainSettingsStorage = BlockchainSettingsStorage(storage: storage)
        initialSyncSettingsManager = InitialSyncSettingsManager(walletManager: walletManager, adapterManager: adapterManager, coinKit: coinKit, storage: settingsStorage)
        ethereumRpcModeSettingsManager = EthereumRpcModeSettingsManager(ethereumKitManager: ethereumKitManager, walletManager: walletManager, adapterManager: adapterManager, localStorage: localStorage)

        transactionDataSortModeSettingManager = TransactionDataSortModeSettingManager(storage: localStorage)

        adapterFactory.initialSyncSettingsManager = initialSyncSettingsManager
        ethereumKitManager.ethereumRpcModeSettingsManager = ethereumRpcModeSettingsManager

        pinKit = PinKit.Kit(secureStorage: keychainKit.secureStorage, localStorage: StorageKit.LocalStorage.default)
        let blurManager: IBlurManager = BlurManager(pinKit: pinKit)

        testModeIndicator = TestModeIndicator(appConfigProvider: appConfigProvider)
        walletRemover = WalletRemover(accountManager: accountManager, walletManager: walletManager)

        let priceAlertRequestStorage: IPriceAlertRequestStorage = PriceAlertRequestStorage(storage: storage)
        remoteAlertManager = RemoteAlertManager(networkManager: networkManager, reachabilityManager: reachabilityManager, appConfigProvider: appConfigProvider, storage: priceAlertRequestStorage)

        let serializer = JsonSerializer()
        let priceAlertStorage: IPriceAlertStorage = PriceAlertStorage(storage: storage)
        priceAlertManager = PriceAlertManager(walletManager: walletManager, remoteAlertManager: remoteAlertManager, rateManager: rateManager, storage: priceAlertStorage, localStorage: localStorage, serializer: serializer)

        notificationManager = NotificationManager(priceAlertManager: priceAlertManager, remoteAlertManager: remoteAlertManager, rateManager: rateManager, storage: localStorage, serializer: serializer)

        remoteAlertManager.notificationManager = notificationManager

        let appVersionStorage: IAppVersionStorage = AppVersionStorage(storage: storage)
        appStatusManager = AppStatusManager(systemInfoManager: systemInfoManager, storage: appVersionStorage, accountManager: accountManager, walletManager: walletManager, adapterManager: adapterManager, ethereumKitManager: ethereumKitManager, binanceSmartChainKitManager: binanceSmartChainKitManager, binanceKitManager: binanceKitManager, logRecordManager: logRecordManager, restoreSettingsManager: restoreSettingsManager)
        appVersionManager = AppVersionManager(systemInfoManager: systemInfoManager, storage: appVersionStorage)

        keychainKitDelegate = KeychainKitDelegate(accountManager: accountManager, walletManager: walletManager)
        keychainKit.set(delegate: keychainKitDelegate)

        pinKitDelegate = PinKitDelegate()
        pinKit.set(delegate: pinKitDelegate)

        rateAppManager = RateAppManager(walletManager: walletManager, adapterManager: adapterManager, localStorage: localStorage)

        guidesManager = GuidesManager(networkManager: networkManager)
        termsManager = TermsManager(storage: StorageKit.LocalStorage.default)

        walletConnectSessionManager = WalletConnectSessionManager(storage: storage, accountManager: accountManager)
        walletConnectManager = WalletConnectManager(accountManager: accountManager, ethereumKitManager: ethereumKitManager, binanceSmartChainKitManager: binanceSmartChainKitManager)

        activateCoinManager = ActivateCoinManager(coinKit: coinKit, walletManager: walletManager, accountManager: accountManager)

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
                logRecordManager: logRecordManager
        )
    }

}
