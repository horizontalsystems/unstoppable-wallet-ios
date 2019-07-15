class App {
    static let shared = App()

    private let fallbackLanguage = "en"

    let pasteboardManager: IPasteboardManager
    let randomManager: IRandomManager

    let localStorage: ILocalStorage

    let appConfigProvider: IAppConfigProvider
    let systemInfoManager: ISystemInfoManager
    let backgroundManager: BackgroundManager
    let biometryManager: IBiometryManager

    let localizationManager: LocalizationManager
    let languageManager: ILanguageManager

    let urlManager: IUrlManager
    let pingManager: IPingManager
    let networkManager: NetworkManager
    let reachabilityManager: IReachabilityManager

    let grdbStorage: GrdbStorage

    let pinManager: IPinManager
    let wordsManager: IWordsManager

    let accountManager: IAccountManager
    let accountCreator: IAccountCreator
    let predefinedAccountTypeManager: IPredefinedAccountTypeManager

    let backupManager: IBackupManager

    let walletManager: IWalletManager
    let walletCreator: IWalletCreator

    let rateManager: RateManager
    let currencyManager: ICurrencyManager

    let authManager: AuthManager

    let feeRateProvider: IFeeRateProvider

    let ethereumKitManager: IEthereumKitManager
    let adapterFactory: IAdapterFactory
    let adapterManager: IAdapterManager

    let lockRouter: LockRouter
    let lockManager: ILockManager
    let blurManager: IBlurManager

    let rateSyncer: RateSyncer

    let dataProviderManager: IFullTransactionDataProviderManager
    let fullTransactionInfoProviderFactory: IFullTransactionInfoProviderFactory

    private let testModeIndicator: TestModeIndicator

    let appManager: IAppManager

    init() {
        pasteboardManager = PasteboardManager()
        randomManager = RandomManager()

        localStorage = UserDefaultsStorage()

        appConfigProvider = AppConfigProvider()
        systemInfoManager = SystemInfoManager()
        backgroundManager = BackgroundManager()
        biometryManager = BiometryManager(systemInfoManager: systemInfoManager)

        localizationManager = LocalizationManager()
        languageManager = LanguageManager(localizationManager: localizationManager, localStorage: localStorage, fallbackLanguage: fallbackLanguage)

        urlManager = UrlManager(inApp: true)
        pingManager = PingManager()
        networkManager = NetworkManager()
        reachabilityManager = ReachabilityManager(appConfigProvider: appConfigProvider)

        grdbStorage = GrdbStorage()

        pinManager = PinManager(secureStorage: KeychainStorage.shared)
        wordsManager = WordsManager(localStorage: localStorage)

        accountManager = AccountManager(storage: grdbStorage)
        accountCreator = AccountCreator(accountManager: accountManager, accountFactory: AccountFactory())
        predefinedAccountTypeManager = PredefinedAccountTypeManager(appConfigProvider: appConfigProvider, accountManager: accountManager, accountCreator: accountCreator, wordsManager: wordsManager)

        backupManager = BackupManager(accountManager: accountManager)

        walletManager = WalletManager(appConfigProvider: appConfigProvider, accountManager: accountManager, storage: grdbStorage)
        walletCreator = WalletCreator(accountManager: accountManager, walletFactory: WalletFactory())

        let rateApiProvider: IRateApiProvider = RateApiProvider(networkManager: networkManager, appConfigProvider: appConfigProvider)
        rateManager = RateManager(storage: grdbStorage, apiProvider: rateApiProvider)
        currencyManager = CurrencyManager(localStorage: localStorage, appConfigProvider: appConfigProvider)

        ethereumKitManager = EthereumKitManager(appConfigProvider: appConfigProvider)

        authManager = AuthManager(secureStorage: KeychainStorage.shared, localStorage: localStorage, pinManager: pinManager, coinManager: walletManager, rateManager: rateManager, ethereumKitManager: ethereumKitManager)

        feeRateProvider = FeeRateProvider()

        adapterFactory = AdapterFactory(appConfigProvider: appConfigProvider, ethereumKitManager: ethereumKitManager, feeRateProvider: feeRateProvider)
        adapterManager = AdapterManager(adapterFactory: adapterFactory, ethereumKitManager: ethereumKitManager, authManager: authManager, walletManager: walletManager)

        lockRouter = LockRouter()
        lockManager = LockManager(pinManager: pinManager, localStorage: localStorage, lockRouter: lockRouter)
        blurManager = BlurManager(lockManager: lockManager)

        rateSyncer = RateSyncer(rateManager: rateManager, adapterManager: adapterManager, currencyManager: currencyManager, reachabilityManager: reachabilityManager)

        dataProviderManager = FullTransactionDataProviderManager(localStorage: localStorage, appConfigProvider: appConfigProvider)

        let jsonApiProvider: IJsonApiProvider = JsonApiProvider(networkManager: networkManager)
        fullTransactionInfoProviderFactory = FullTransactionInfoProviderFactory(apiProvider: jsonApiProvider, dataProviderManager: dataProviderManager)

        testModeIndicator = TestModeIndicator(appConfigProvider: appConfigProvider)

        authManager.adapterManager = adapterManager

        appManager = AppManager(accountManager: accountManager, adapterManager: adapterManager, lockManager: lockManager, biometryManager: biometryManager, blurManager: blurManager)
    }

}
