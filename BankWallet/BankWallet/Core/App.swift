class App {
    static let shared = App()

    private let fallbackLanguage = "en"

    let pasteboardManager: IPasteboardManager
    let randomManager: IRandomManager

    let localStorage: ILocalStorage
    let secureStorage: ISecureStorage

    let appConfigProvider: IAppConfigProvider
    let systemInfoManager: ISystemInfoManager

    let localizationManager: LocalizationManager
    let languageManager: ILanguageManager

    let urlManager: IUrlManager
    let pingManager: IPingManager
    let networkManager: NetworkManager
    let reachabilityManager: IReachabilityManager

    let grdbStorage: GrdbStorage
    let tokenSyncer: ITokenSyncer

    let pinManager: IPinManager
    let coinManager: ICoinManager
    let rateManager: RateManager
    let currencyManager: ICurrencyManager

    let authManager: AuthManager
    let wordsManager: IWordsManager

    let ethereumKitManager: IEthereumKitManager
    let adapterFactory: IAdapterFactory
    let adapterManager: IAdapterManager

    let lockRouter: LockRouter
    let lockManager: ILockManager
    let blurManager: IBlurManager

    let rateSyncer: RateSyncer

    let dataProviderManager: IFullTransactionDataProviderManager
    let fullTransactionInfoProviderFactory: IFullTransactionInfoProviderFactory

    init() {
        pasteboardManager = PasteboardManager()
        randomManager = RandomManager()

        localStorage = UserDefaultsStorage()
        secureStorage = KeychainStorage(localStorage: localStorage)

        appConfigProvider = AppConfigProvider()
        systemInfoManager = SystemInfoManager()

        localizationManager = LocalizationManager()
        languageManager = LanguageManager(localizationManager: localizationManager, localStorage: localStorage, fallbackLanguage: fallbackLanguage)

        urlManager = UrlManager(inApp: true)
        pingManager = PingManager()
        networkManager = NetworkManager(appConfigProvider: appConfigProvider)
        reachabilityManager = ReachabilityManager(appConfigProvider: appConfigProvider)

        grdbStorage = GrdbStorage()
        tokenSyncer = TokenSyncer(tokenNetworkManager: networkManager, storage: grdbStorage)

        pinManager = PinManager(secureStorage: secureStorage)
        coinManager = CoinManager(appConfigProvider: appConfigProvider, storage: grdbStorage)
        rateManager = RateManager(storage: grdbStorage, networkManager: networkManager)
        currencyManager = CurrencyManager(localStorage: localStorage, appConfigProvider: appConfigProvider)

        ethereumKitManager = EthereumKitManager(appConfigProvider: appConfigProvider)

        authManager = AuthManager(secureStorage: secureStorage, localStorage: localStorage, pinManager: pinManager, coinManager: coinManager, rateManager: rateManager, ethereumKitManager: ethereumKitManager)
        wordsManager = WordsManager(localStorage: localStorage)

        adapterFactory = AdapterFactory(appConfigProvider: appConfigProvider, localStorage: localStorage, ethereumKitManager: ethereumKitManager)
        adapterManager = AdapterManager(adapterFactory: adapterFactory, authManager: authManager, coinManager: coinManager)

        lockRouter = LockRouter()
        lockManager = LockManager(localStorage: localStorage, authManager: authManager, appConfigProvider: appConfigProvider, lockRouter: lockRouter)
        blurManager = BlurManager(lockManager: lockManager)

        rateSyncer = RateSyncer(rateManager: rateManager, adapterManager: adapterManager, currencyManager: currencyManager, reachabilityManager: reachabilityManager)

        dataProviderManager = FullTransactionDataProviderManager(localStorage: localStorage, appConfigProvider: appConfigProvider)
        fullTransactionInfoProviderFactory = FullTransactionInfoProviderFactory(apiManager: networkManager, dataProviderManager: dataProviderManager)

        authManager.adapterManager = adapterManager
    }

}
