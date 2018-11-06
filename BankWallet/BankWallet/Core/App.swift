import Foundation
import RealmSwift

class App {
    static let shared = App()

    private let fallbackLanguage = "en"

    let realmFactory: IRealmFactory

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

    let adapterFactory: IAdapterFactory
    let walletManager: IWalletManager

    let appConfigProvider: IAppConfigProvider
    let coinManager: ICoinManager

    let realmStorage: RealmStorage
    let networkManager: NetworkManager

    let reachabilityManager: IReachabilityManager

    let currencyManager: ICurrencyManager

    var rateSyncer: IRateSyncer
    let rateManager: RateManager

    let transactionRateSyncer: ITransactionRateSyncer
    let transactionManager: ITransactionManager

    init() {
        let realmFileName = "bank.realm"

        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let realmConfiguration = Realm.Configuration(fileURL: documentsUrl?.appendingPathComponent(realmFileName))

        realmFactory = RealmFactory(configuration: realmConfiguration)

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

        adapterFactory = AdapterFactory()
        walletManager = WalletManager(adapterFactory: adapterFactory)

        appConfigProvider = AppConfigProvider()
        coinManager = CoinManager(wordsManager: wordsManager, walletManager: walletManager, appConfigProvider: appConfigProvider)

        realmStorage = RealmStorage(realmFactory: realmFactory)
        networkManager = NetworkManager(apiUrl: "https://ipfs.grouvi.im/ipns/QmSxpioQuDSjTH6XiT5q35V7xpJqxmDheEcTRRWyMkMim7/io-hs/data/xrates")

        reachabilityManager = ReachabilityManager()

        currencyManager = CurrencyManager(localStorage: localStorage, appConfigProvider: appConfigProvider)

        rateSyncer = RateSyncer(networkManager: networkManager)
        rateManager = RateManager(storage: realmStorage, syncer: rateSyncer, walletManager: walletManager, currencyManager: currencyManager, reachabilityManager: reachabilityManager, timer: Timer(interval: 5 * 60))
        rateSyncer.delegate = rateManager

        transactionRateSyncer = TransactionRateSyncer(storage: realmStorage, networkManager: networkManager)
        transactionManager = TransactionManager(storage: realmStorage, rateSyncer: transactionRateSyncer, walletManager: walletManager, currencyManager: currencyManager)

    }

}
