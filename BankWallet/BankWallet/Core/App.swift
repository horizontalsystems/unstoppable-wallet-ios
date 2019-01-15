import RealmSwift

class App {
    static let shared = App()

    private let fallbackLanguage = "en"

    let pasteboardManager: IPasteboardManager
    let urlManager: IUrlManager

    let realmFactory: IRealmFactory

    let secureStorage: ISecureStorage
    let localStorage: ILocalStorage

    let authManager: AuthManager
    let wordsManager: IWordsManager

    let appConfigProvider: IAppConfigProvider

    let pinManager: IPinManager
    let lockRouter: LockRouter
    let lockManager: ILockManager
    let blurManager: IBlurManager

    let localizationManager: LocalizationManager
    let languageManager: ILanguageManager

    let randomManager: IRandomManager
    let systemInfoManager: ISystemInfoManager

    let coinManager: ICoinManager

    let adapterFactory: IAdapterFactory
    let walletFactory: IWalletFactory
    let walletManager: IWalletManager

    let realmStorage: RealmStorage
    let grdbStorage: GrdbStorage
    let networkManager: NetworkManager

    let reachabilityManager: IReachabilityManager

    let currencyManager: ICurrencyManager

    var rateSyncer: RateSyncer
    let rateManager: RateManager

    let transactionRateSyncer: ITransactionRateSyncer
    let transactionManager: ITransactionManager

    let settingsProviderMap: ISettingsProviderMap
    let transactionViewItemFactory: ITransactionViewItemFactory
    let fullTransactionInfoProviderFactory: IFullTransactionInfoProviderFactory

    init() {
        pasteboardManager = PasteboardManager()
        urlManager = UrlManager(inApp: true)

        realmFactory = RealmFactory()

        localStorage = UserDefaultsStorage()
        secureStorage = KeychainStorage(localStorage: localStorage)

        authManager = AuthManager(secureStorage: secureStorage, localStorage: localStorage)
        wordsManager = WordsManager(localStorage: localStorage)

        appConfigProvider = AppConfigProvider()

        pinManager = PinManager(secureStorage: secureStorage)
        lockRouter = LockRouter()
        lockManager = LockManager(localStorage: localStorage, authManager: authManager, appConfigProvider: appConfigProvider, lockRouter: lockRouter)
        blurManager = BlurManager(lockManager: lockManager)

        localizationManager = LocalizationManager()
        languageManager = LanguageManager(localizationManager: localizationManager, localStorage: localStorage, fallbackLanguage: fallbackLanguage)

        randomManager = RandomManager()
        systemInfoManager = SystemInfoManager()

        coinManager = CoinManager(appConfigProvider: appConfigProvider)

        adapterFactory = AdapterFactory(appConfigProvider: appConfigProvider)
        walletFactory = WalletFactory(adapterFactory: adapterFactory)
        walletManager = WalletManager(walletFactory: walletFactory, authManager: authManager, coinManager: coinManager)

        realmStorage = RealmStorage(realmFactory: realmFactory)
        grdbStorage = GrdbStorage()
        networkManager = NetworkManager(appConfigProvider: appConfigProvider)

        reachabilityManager = ReachabilityManager(appConfigProvider: appConfigProvider)

        currencyManager = CurrencyManager(localStorage: localStorage, appConfigProvider: appConfigProvider)

        rateManager = RateManager(storage: grdbStorage, networkManager: networkManager)
        rateSyncer = RateSyncer(rateManager: rateManager, walletManager: walletManager, currencyManager: currencyManager, reachabilityManager: reachabilityManager)

        transactionRateSyncer = TransactionRateSyncer(storage: realmStorage, networkManager: networkManager)
        transactionManager = TransactionManager(storage: realmStorage, rateSyncer: transactionRateSyncer, walletManager: walletManager, currencyManager: currencyManager, reachabilityManager: reachabilityManager)

        transactionViewItemFactory = TransactionViewItemFactory(walletManager: walletManager, currencyManager: currencyManager, rateManager: rateManager)

        authManager.walletManager = walletManager
        authManager.pinManager = pinManager
        authManager.transactionsManager = transactionManager

        settingsProviderMap = SettingsProviderMap()
        fullTransactionInfoProviderFactory = FullTransactionInfoProviderFactory(apiManager: networkManager, appConfigProvider: appConfigProvider, providerMap: settingsProviderMap, localStorage: localStorage)
    }

}
