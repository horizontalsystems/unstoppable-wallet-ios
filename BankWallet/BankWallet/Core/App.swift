class App {
    static let shared = App()

    private let fallbackLanguage = "en"

    let pasteboardManager: IPasteboardManager
    let randomManager: IRandomManager

    let localStorage: ILocalStorage
    let secureStorage: ISecureStorage

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
    let accountStorage: IAccountStorage

    let pinManager: IPinManager
    let wordsManager: IWordsManager

    let accountManager: IAccountManager
    let backupManager: IBackupManager

    let walletFactory: IWalletFactory
    let walletStorage: IWalletStorage
    let walletManager: IWalletManager
    let defaultWalletCreator: IDefaultWalletCreator
    let walletRemover: WalletRemover

    let accountCreator: IAccountCreator
    let predefinedAccountTypeManager: IPredefinedAccountTypeManager

    let rateManager: RateManager
    let currencyManager: ICurrencyManager

    let feeRateProviderFactory: FeeRateProviderFactory
    let addressParserFactory: AddressParserFactory

    let ethereumKitManager: EthereumKitManager
    let eosKitManager: EosKitManager
    let binanceKitManager: BinanceKitManager

    let adapterFactory: IAdapterFactory
    let adapterManager: IAdapterManager

    let lockRouter: LockRouter
    let lockManager: ILockManager
    let blurManager: IBlurManager

    let passcodeLockRouter: IPasscodeLockRouter
    let passcodeLockManager: IPasscodeLockManager

    let rateSyncer: RateSyncer

    let dataProviderManager: IFullTransactionDataProviderManager
    let fullTransactionInfoProviderFactory: IFullTransactionInfoProviderFactory

    private let testModeIndicator: TestModeIndicator

    let appManager: IAppManager

    init() {
        pasteboardManager = PasteboardManager()
        randomManager = RandomManager()

        localStorage = UserDefaultsStorage()
        secureStorage = KeychainStorage()

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
        accountStorage = AccountStorage(secureStorage: secureStorage, storage: grdbStorage)

        pinManager = PinManager(secureStorage: secureStorage)
        wordsManager = WordsManager(localStorage: localStorage)

        accountManager = AccountManager(storage: accountStorage)
        backupManager = BackupManager(accountManager: accountManager)

        walletFactory = WalletFactory()
        walletStorage = WalletStorage(appConfigProvider: appConfigProvider, walletFactory: walletFactory, storage: grdbStorage)
        walletManager = WalletManager(accountManager: accountManager, walletFactory: walletFactory, storage: walletStorage)
        defaultWalletCreator = DefaultWalletCreator(walletManager: walletManager, appConfigProvider: appConfigProvider, walletFactory: walletFactory)
        walletRemover = WalletRemover(accountManager: accountManager, walletManager: walletManager)

        accountCreator = AccountCreator(accountManager: accountManager, accountFactory: AccountFactory(), wordsManager: wordsManager, defaultWalletCreator: defaultWalletCreator)
        predefinedAccountTypeManager = PredefinedAccountTypeManager(appConfigProvider: appConfigProvider, accountManager: accountManager, accountCreator: accountCreator)

        let rateApiProvider: IRateApiProvider = RateApiProvider(networkManager: networkManager, appConfigProvider: appConfigProvider)
        rateManager = RateManager(storage: grdbStorage, apiProvider: rateApiProvider)
        currencyManager = CurrencyManager(localStorage: localStorage, appConfigProvider: appConfigProvider)

        ethereumKitManager = EthereumKitManager(appConfigProvider: appConfigProvider)
        eosKitManager = EosKitManager(appConfigProvider: appConfigProvider)
        binanceKitManager = BinanceKitManager(appConfigProvider: appConfigProvider)

        feeRateProviderFactory = FeeRateProviderFactory()
        addressParserFactory = AddressParserFactory()

        adapterFactory = AdapterFactory(appConfigProvider: appConfigProvider, ethereumKitManager: ethereumKitManager, eosKitManager: eosKitManager, binanceKitManager: binanceKitManager)
        adapterManager = AdapterManager(adapterFactory: adapterFactory, ethereumKitManager: ethereumKitManager, eosKitManager: eosKitManager, binanceKitManager: binanceKitManager, walletManager: walletManager)

        lockRouter = LockRouter()
        lockManager = LockManager(pinManager: pinManager, localStorage: localStorage, lockRouter: lockRouter)
        blurManager = BlurManager(lockManager: lockManager)

        passcodeLockRouter = PasscodeLockRouter()
        passcodeLockManager = PasscodeLockManager(systemInfoManager: systemInfoManager, accountManager: accountManager, walletManager: walletManager, router: passcodeLockRouter)

        rateSyncer = RateSyncer(rateManager: rateManager, walletManager: walletManager, currencyManager: currencyManager, reachabilityManager: reachabilityManager)

        dataProviderManager = FullTransactionDataProviderManager(localStorage: localStorage, appConfigProvider: appConfigProvider)

        let jsonApiProvider: IJsonApiProvider = JsonApiProvider(networkManager: networkManager)
        fullTransactionInfoProviderFactory = FullTransactionInfoProviderFactory(apiProvider: jsonApiProvider, dataProviderManager: dataProviderManager)

        testModeIndicator = TestModeIndicator(appConfigProvider: appConfigProvider)

        appManager = AppManager(
                accountManager: accountManager,
                walletManager: walletManager,
                adapterManager: adapterManager,
                lockManager: lockManager,
                passcodeLockManager: passcodeLockManager,
                biometryManager: biometryManager,
                blurManager: blurManager,
                localStorage: localStorage,
                secureStorage: secureStorage
        )
    }

}
