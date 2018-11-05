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

    let currencyManager: ICurrencyManager
    let rateManager: IRateManager

    let transactionManager: ITransactionManager

    let reachabilityManager: IReachabilityManager

    let rateSyncer: RateSyncer

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

        currencyManager = CurrencyManager(localStorage: localStorage, appConfigProvider: appConfigProvider)
        rateManager = RateManager(rateStorage: realmStorage, transactionRecordStorage: realmStorage, currencyManager: currencyManager, networkManager: networkManager, walletManager: walletManager)

        transactionManager = TransactionManager(walletManager: walletManager, realmFactory: realmFactory, rateManager: rateManager)

        reachabilityManager = ReachabilityManager()

        rateSyncer = RateSyncer(rateManager: rateManager, reachabilityManager: reachabilityManager, walletManager: walletManager, timer: Timer(interval: 5 * 60))
    }

}
