class App {
    static let shared = App()

    private let fallbackLanguage = "en"

    let pasteboardManager: IPasteboardManager
    let randomManager: IRandomManager

    let appConfigProvider: IAppConfigProvider
    let systemInfoManager: ISystemInfoManager
    let backgroundManager: BackgroundManager

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

    let walletManager: IWalletManager

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

    init() {
        pasteboardManager = PasteboardManager()
        randomManager = RandomManager()

        appConfigProvider = AppConfigProvider()
        systemInfoManager = SystemInfoManager()
        backgroundManager = BackgroundManager()

        localizationManager = LocalizationManager()
        languageManager = LanguageManager(localizationManager: localizationManager, localStorage: UserDefaultsStorage.shared, fallbackLanguage: fallbackLanguage)

        urlManager = UrlManager(inApp: true)
        pingManager = PingManager()
        networkManager = NetworkManager()
        reachabilityManager = ReachabilityManager(appConfigProvider: appConfigProvider)

        grdbStorage = GrdbStorage()

        pinManager = PinManager(secureStorage: KeychainStorage.shared)
        wordsManager = WordsManager(localStorage: UserDefaultsStorage.shared)

        accountManager = AccountManager(storage: grdbStorage)
        accountCreator = AccountCreator(accountManager: accountManager, accountFactory: AccountFactory(), wordsManager: wordsManager)

        walletManager = WalletManager(appConfigProvider: appConfigProvider, accountManager: accountManager, storage: grdbStorage)

        let rateApiProvider: IRateApiProvider = RateApiProvider(networkManager: networkManager, appConfigProvider: appConfigProvider)
        rateManager = RateManager(storage: grdbStorage, apiProvider: rateApiProvider)
        currencyManager = CurrencyManager(localStorage: UserDefaultsStorage.shared, appConfigProvider: appConfigProvider)

        ethereumKitManager = EthereumKitManager(appConfigProvider: appConfigProvider)

        authManager = AuthManager(secureStorage: KeychainStorage.shared, localStorage: UserDefaultsStorage.shared, pinManager: pinManager, coinManager: walletManager, rateManager: rateManager, ethereumKitManager: ethereumKitManager)

        feeRateProvider = FeeRateProvider()

        adapterFactory = AdapterFactory(appConfigProvider: appConfigProvider, ethereumKitManager: ethereumKitManager, feeRateProvider: feeRateProvider)
        adapterManager = AdapterManager(adapterFactory: adapterFactory, ethereumKitManager: ethereumKitManager, authManager: authManager, walletManager: walletManager)

        lockRouter = LockRouter()
        lockManager = LockManager(localStorage: UserDefaultsStorage.shared, authManager: authManager, appConfigProvider: appConfigProvider, lockRouter: lockRouter)
        blurManager = BlurManager(lockManager: lockManager)

        rateSyncer = RateSyncer(rateManager: rateManager, adapterManager: adapterManager, currencyManager: currencyManager, reachabilityManager: reachabilityManager)

        dataProviderManager = FullTransactionDataProviderManager(localStorage: UserDefaultsStorage.shared, appConfigProvider: appConfigProvider)

        let jsonApiProvider: IJsonApiProvider = JsonApiProvider(networkManager: networkManager)
        fullTransactionInfoProviderFactory = FullTransactionInfoProviderFactory(apiProvider: jsonApiProvider, dataProviderManager: dataProviderManager)

        testModeIndicator = TestModeIndicator(appConfigProvider: appConfigProvider)

        authManager.adapterManager = adapterManager
    }

}
