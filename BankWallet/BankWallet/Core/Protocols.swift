import RxSwift
import RealmSwift

typealias Coin = String

protocol IRandomManager {
    func getRandomIndexes(count: Int) -> [Int]
}

protocol IRealmFactory {
    var realm: Realm { get }
}

protocol ILocalStorage: class {
    var isBackedUp: Bool { get set }
    var baseCurrencyCode: String? { get set }
    var lightMode: Bool { get set }
    var iUnderstand: Bool { get set }
    var isBiometricOn: Bool { get set }
    var currentLanguage: String? { get set }
    var lastExitDate: Double { get set }
    var didLaunchOnce: Bool { get }
    func clear()
}

protocol ISecureStorage: class {
    var words: [String]? { get }
    func set(words: [String]?) throws
    var pin: String? { get }
    func set(pin: String?) throws
    var unlockAttempts: Int? { get }
    func set(unlockAttempts: Int?) throws
    var lockoutTimestamp: TimeInterval? { get }
    func set(lockoutTimestamp: TimeInterval?) throws
    func clear()
}

protocol ILanguageManager {
    var currentLanguage: String { get set }
    var displayNameForCurrentLanguage: String { get }

    func localize(string: String) -> String
    func localize(string: String, arguments: [CVarArg]) -> String
}

protocol ILocalizationManager {
    var preferredLanguage: String? { get }
    var availableLanguages: [String] { get }
    func displayName(forLanguage language: String, inLanguage: String) -> String

    func setLocale(forLanguage language: String)
    func localize(string: String, language: String) -> String?
    func format(localizedString: String, arguments: [CVarArg]) -> String
}

protocol IWalletManager {
    var wallets: [Wallet] { get }
    var walletsSubject: PublishSubject<[Wallet]> { get }

    func initWallets(words: [String], coins: [Coin])
    func refreshWallets()
    func clearWallets()
}

protocol IAdapterFactory {
    func adapter(forCoin coin: Coin, words: [String]) -> IAdapter?
}

protocol ICoinManager {
}

protocol ITransactionManager: class {
}

enum AdapterState {
    case synced
    case syncing(progressSubject: BehaviorSubject<Double>)
    case notSynced
}

protocol IAdapter: class {
    var balance: Double { get }
    var balanceSubject: PublishSubject<Double> { get }

    var state: AdapterState { get }
    var stateSubject: PublishSubject<AdapterState> { get }

    var confirmationsThreshold: Int { get }
    var lastBlockHeight: Int? { get }
    var lastBlockHeightSubject: PublishSubject<Int> { get }

    var transactionRecordsSubject: PublishSubject<[TransactionRecord]> { get }

    var debugInfo: String { get }

    func start()
    func refresh()
    func clear()

    func send(to address: String, value: Double, completion: ((Error?) -> ())?)

    func fee(for value: Double, address: String?, senderPay: Bool) throws -> Double
    func validate(address: String) throws
    func parse(paymentAddress: String) -> PaymentRequestAddress

    var receiveAddress: String { get }
}

protocol IWordsManager {
    var words: [String]? { get }
    var isBackedUp: Bool { get set }
    var isLoggedIn: Bool { get }
    var loggedInSubject: PublishSubject<Bool> { get }
    var backedUpSubject: PublishSubject<Bool> { get }
    func createWords() throws
    func validate(words: [String]) throws
    func restore(withWords words: [String]) throws
    func logout()
}

protocol ILockManager {
    var isLocked: Bool { get }
    func lock()
    func didEnterBackground()
    func willEnterForeground()
}

protocol IBlurManager {
    func willResignActive()
    func didBecomeActive()
}

protocol IPinManager {
    var isPinSet: Bool { get }
    func store(pin: String?) throws
    func validate(pin: String) -> Bool
}

protocol ILockRouter {
    func showUnlock(delegate: IUnlockDelegate?)
}

protocol IBiometricManager {
    func validate(reason: String)
}

protocol BiometricManagerDelegate: class {
    func didValidate()
    func didFailToValidate()
}

protocol IRateManager {
    var subject: PublishSubject<Void> { get }
    func rate(forCoin coin: Coin, currencyCode: String) -> Rate?
}

protocol IRateSyncer {
    var delegate: IRateSyncerDelegate? { get set }
    func sync(coins: [String], currencyCode: String)
}

protocol IRateSyncerDelegate: class {
    func didSync(coin: String, currencyCode: String, latestRate: LatestRate)
}

protocol ISystemInfoManager {
    var appVersion: String { get }
    var biometryType: BiometryType { get }
}

protocol IAppConfigProvider {
    var reachabilityHost: String { get }
    var ratesApiUrl: String { get }
    var enabledCoins: [Coin] { get }
    var currencies: [Currency] { get }
}

protocol IRateNetworkManager {
    func getLatestRate(coin: String, currencyCode: String) -> Observable<LatestRate>
    func getRate(coin: String, currencyCode: String, date: Date) -> Observable<Double>
}

protocol IRateStorage {
    func rate(forCoin coin: Coin, currencyCode: String) -> Rate?
    func save(latestRate: LatestRate, coin: Coin, currencyCode: String)
    func clear()
}

protocol ITransactionRecordStorage {
    func record(forHash hash: String) -> TransactionRecord?
    var nonFilledRecords: [TransactionRecord] { get }
    func set(rate: Double, transactionHash: String)
    func clearRates()

    func update(records: [TransactionRecord])
    func clearRecords()
}

protocol ICurrencyManager {
    var subject: PublishSubject<Currency> { get }
    var currencies: [Currency] { get }
    var baseCurrency: Currency { get }

    func setBaseCurrency(code: String)
}

protocol IReachabilityManager {
    var subject: PublishSubject<Bool> { get }
}

protocol IPeriodicTimer {
    var delegate: IPeriodicTimerDelegate? { get set }
    func schedule()
}

protocol IOneTimeTimer {
    var delegate: IPeriodicTimerDelegate? { get set }
    func schedule(date: Date)
}

protocol IPeriodicTimerDelegate: class {
    func onFire()
}

protocol ITransactionRateSyncer {
    func sync(currencyCode: String)
    func cancelCurrentSync()
}

protocol IPasteboardManager {
    var value: String? { get }
    func set(value: String)
}

protocol ITransactionViewItemFactory {
    func item(fromRecord record: TransactionRecord) -> TransactionViewItem
}

protocol ILockoutManager {
    var delegate: ILockoutManagerDelegate? { get set }
    var isLockedOut: Bool { get }
    var failedTimes: Int? { get set }
    var attemptsLeft: Int { get }
    var lockoutTimeFrame: TimeInterval { get }
}

protocol ILockoutManagerDelegate: class {
    func lockout(timeFrame: TimeInterval)
    func finishLockout()
}

protocol IUptimeProvider {
    var uptime: TimeInterval { get }
}

protocol ILockoutTimeFrameFactory {
    func lockoutTimeFrame(failedAttempts: Int, lockoutTimestamp: TimeInterval, uptime: TimeInterval) -> TimeInterval
}

protocol ILockoutManagerNew {
    var currentState: LockoutStateNew { get }
    func didFailUnlock()
}
