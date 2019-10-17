class App {
    static let shared = App()

    let localStorage: ILocalStorage
    let secureStorage: ISecureStorage
    let storage: IRateStorage & IEnabledWalletStorage & IAccountRecordStorage & IPriceAlertRecordStorage

    let themeManager: IThemeManager
    let appConfigProvider: IAppConfigProvider
    let systemInfoManager: ISystemInfoManager
    let biometryManager: IBiometryManager

    let pasteboardManager: IPasteboardManager
    let reachabilityManager: IReachabilityManager

    let languageManager: LanguageManager

    let pinManager: IPinManager
    let wordsManager: IWordsManager

    let accountManager: IAccountManager
    let backupManager: IBackupManager

    let walletFactory: IWalletFactory
    let walletManager: IWalletManager

    let accountCreator: IAccountCreator
    let predefinedAccountTypeManager: IPredefinedAccountTypeManager

    let currencyManager: ICurrencyManager

    let rateManager: RateManager
    let rateStatsManager: IRateStatsManager

    let feeCoinProvider: IFeeCoinProvider
    let feeRateProviderFactory: FeeRateProviderFactory

    let adapterManager: IAdapterManager

    let lockRouter: LockRouter

    let passcodeLockManager: IPasscodeLockManager

    let dataProviderManager: IFullTransactionDataProviderManager
    let fullTransactionInfoProviderFactory: IFullTransactionInfoProviderFactory

    private let testModeIndicator: TestModeIndicator
    private let walletRemover: WalletRemover
    private let rateSyncScheduler: RateSyncScheduler

    let priceAlertManager: IPriceAlertManager
    let backgroundPriceAlertManager: IBackgroundPriceAlertManager
    let notificationManager: INotificationManager
    var debugBackgroundLogger: IDebugBackgroundLogger?

    let appStatusManager: IAppStatusManager
    let appVersionManager: IAppVersionManager

    let appManager: AppManager

    init() {
        let networkManager = NetworkManager()

        localStorage = UserDefaultsStorage()
        secureStorage = KeychainStorage()
        storage = GrdbStorage()

        themeManager = ThemeManager(localStorage: localStorage)
        appConfigProvider = AppConfigProvider()
        systemInfoManager = SystemInfoManager()
        biometryManager = BiometryManager(systemInfoManager: systemInfoManager)

        pasteboardManager = PasteboardManager()
        reachabilityManager = ReachabilityManager(appConfigProvider: appConfigProvider)

        languageManager = LanguageManager(localStorage: localStorage)

        pinManager = PinManager(secureStorage: secureStorage, localStorage: localStorage)
        wordsManager = WordsManager(localStorage: localStorage)

        let accountStorage: IAccountStorage = AccountStorage(secureStorage: secureStorage, storage: storage)
        accountManager = AccountManager(storage: accountStorage)
        backupManager = BackupManager(accountManager: accountManager)

        walletFactory = WalletFactory()
        let walletStorage: IWalletStorage = WalletStorage(appConfigProvider: appConfigProvider, walletFactory: walletFactory, storage: storage)
        walletManager = WalletManager(accountManager: accountManager, walletFactory: walletFactory, storage: walletStorage)

        let defaultWalletCreator: IDefaultWalletCreator = DefaultWalletCreator(walletManager: walletManager, appConfigProvider: appConfigProvider, walletFactory: walletFactory)
        accountCreator = AccountCreator(accountManager: accountManager, accountFactory: AccountFactory(), wordsManager: wordsManager, defaultWalletCreator: defaultWalletCreator)
        predefinedAccountTypeManager = PredefinedAccountTypeManager(appConfigProvider: appConfigProvider, accountManager: accountManager, accountCreator: accountCreator)

        currencyManager = CurrencyManager(localStorage: localStorage, appConfigProvider: appConfigProvider)

        let ipfsApiProvider = IpfsApiProvider(appConfigProvider: appConfigProvider)
        let rateApiProvider: IRateApiProvider = RateApiProvider(networkManager: networkManager, ipfsApiProvider: ipfsApiProvider)
        rateManager = RateManager(storage: storage, apiProvider: rateApiProvider, walletManager: walletManager, reachabilityManager: reachabilityManager, currencyManager: currencyManager)

        let chartApiProvider = RatesStatsApiProvider(networkManager: networkManager, ipfsApiProvider: ipfsApiProvider)
        let chartRateConverter = ChartRateDataConverter()
        rateStatsManager = RateStatsManager(apiProvider: chartApiProvider, rateStorage: storage, chartRateConverter: chartRateConverter)

        feeCoinProvider = FeeCoinProvider(appConfigProvider: appConfigProvider)
        feeRateProviderFactory = FeeRateProviderFactory()

        let ethereumKitManager = EthereumKitManager(appConfigProvider: appConfigProvider)
        let eosKitManager = EosKitManager(appConfigProvider: appConfigProvider)
        let binanceKitManager = BinanceKitManager(appConfigProvider: appConfigProvider)

        let adapterFactory: IAdapterFactory = AdapterFactory(appConfigProvider: appConfigProvider, ethereumKitManager: ethereumKitManager, eosKitManager: eosKitManager, binanceKitManager: binanceKitManager)
        adapterManager = AdapterManager(adapterFactory: adapterFactory, ethereumKitManager: ethereumKitManager, eosKitManager: eosKitManager, binanceKitManager: binanceKitManager, walletManager: walletManager)

        lockRouter = LockRouter()
        let lockManager: ILockManager = LockManager(pinManager: pinManager, localStorage: localStorage, lockRouter: lockRouter)
        let blurManager: IBlurManager = BlurManager(lockManager: lockManager)

        let passcodeLockRouter: IPasscodeLockRouter = PasscodeLockRouter()
        passcodeLockManager = PasscodeLockManager(systemInfoManager: systemInfoManager, accountManager: accountManager, walletManager: walletManager, router: passcodeLockRouter)

        dataProviderManager = FullTransactionDataProviderManager(localStorage: localStorage, appConfigProvider: appConfigProvider)

        let jsonApiProvider: IJsonApiProvider = JsonApiProvider(networkManager: networkManager)
        fullTransactionInfoProviderFactory = FullTransactionInfoProviderFactory(apiProvider: jsonApiProvider, dataProviderManager: dataProviderManager)

        testModeIndicator = TestModeIndicator(appConfigProvider: appConfigProvider)
        walletRemover = WalletRemover(accountManager: accountManager, walletManager: walletManager)
        rateSyncScheduler = RateSyncScheduler(rateManager: rateManager, walletManager: walletManager, currencyManager: currencyManager, reachabilityManager: reachabilityManager)

        let priceAlertStorage: IPriceAlertStorage = PriceAlertStorage(appConfigProvider: appConfigProvider, storage: storage)
        priceAlertManager = PriceAlertManager(walletManager: walletManager, storage: priceAlertStorage)
        notificationManager = NotificationManager()

        let notificationFactory = NotificationFactory(emojiHelper: EmojiHelper())
        let priceAlertHandler = PriceAlertHandler(priceAlertStorage: priceAlertStorage, notificationManager: notificationManager, notificationFactory: notificationFactory)

        #if DEBUG
            debugBackgroundLogger = DebugBackgroundLogger(localStorage: localStorage, dateProvider: CurrentDateProvider())
        #endif
        backgroundPriceAlertManager = BackgroundPriceAlertManager(rateManager: rateManager, currencyManager: currencyManager, rateStorage: storage, priceAlertStorage: priceAlertStorage, priceAlertHandler: priceAlertHandler, debugBackgroundLogger: debugBackgroundLogger)

        appStatusManager = AppStatusManager(systemInfoManager: systemInfoManager, localStorage: localStorage, accountManager: accountManager, predefinedAccountTypeManager: predefinedAccountTypeManager, walletManager: walletManager, adapterManager: adapterManager)
        appVersionManager = AppVersionManager(systemInfoManager: systemInfoManager, localStorage: localStorage)

        let kitCleaner = KitCleaner(accountManager: accountManager)
        appManager = AppManager(
                accountManager: accountManager,
                walletManager: walletManager,
                adapterManager: adapterManager,
                lockManager: lockManager,
                passcodeLockManager: passcodeLockManager,
                biometryManager: biometryManager,
                blurManager: blurManager,
                notificationManager: notificationManager,
                backgroundPriceAlertManager: backgroundPriceAlertManager,
                localStorage: localStorage,
                secureStorage: secureStorage,
                kitCleaner: kitCleaner,
                debugBackgroundLogger: debugBackgroundLogger,
                appVersionManager: appVersionManager
        )
    }

}

extension App {

    static var theme: ITheme {
        return App.shared.themeManager.currentTheme
    }

}
