class App {
    static let shared = App()

    private let fallbackLanguage = "en"

    let secureStorage: ISecureStorage
    let localStorage: ILocalStorage
    let wordsManager: IWordsManager

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
    let walletManager: IWalletManager

    let exchangeRateManager: IExchangeRateManager

    init() {
        localStorage = UserDefaultsStorage()
        secureStorage = KeychainStorage(localStorage: localStorage)
        wordsManager = WordsManager(secureStorage: secureStorage, localStorage: localStorage)

        pinManager = PinManager(secureStorage: secureStorage)
        lockRouter = LockRouter()
        lockManager = LockManager(localStorage: localStorage, wordsManager: wordsManager, lockRouter: lockRouter)
        blurManager = BlurManager(lockManager: lockManager)

        localizationManager = LocalizationManager()
        languageManager = LanguageManager(localizationManager: localizationManager, localStorage: localStorage, fallbackLanguage: fallbackLanguage)

        randomManager = RandomManager()
        systemInfoManager = SystemInfoManager()

        coinManager = CoinManager()
        adapterFactory = AdapterFactory()
        walletManager = WalletManager(wordsManager: wordsManager, coinManager: coinManager, adapterFactory: adapterFactory)

        exchangeRateManager = ExchangeRateManager()

        walletManager.initWallets()
    }

}
