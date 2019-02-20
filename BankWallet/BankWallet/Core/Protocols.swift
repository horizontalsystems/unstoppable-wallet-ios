import RxSwift

typealias CoinCode = String

protocol IRandomManager {
    func getRandomIndexes(count: Int) -> [Int]
}

protocol ILocalStorage: class {
    var isNewWallet: Bool { get set }
    var isBackedUp: Bool { get set }
    var baseCurrencyCode: String? { get set }
    var baseBitcoinProvider: String? { get set }
    var baseEthereumProvider: String? { get set }
    var lightMode: Bool { get set }
    var iUnderstand: Bool { get set }
    var isBiometricOn: Bool { get set }
    var currentLanguage: String? { get set }
    var lastExitDate: Double { get set }
    var didLaunchOnce: Bool { get }
    var sendInputType: SendInputType? { get set }
    func clear()
}

protocol ISecureStorage: class {
    var authData: AuthData? { get }
    func set(authData: AuthData?) throws
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

protocol IAdapterManager: class {
    var adapters: [IAdapter] { get }
    var adaptersUpdatedSignal: Signal { get }
    func initAdapters()
    func clear()
    func willEnterForeground()
}

protocol IAdapterFactory {
    func adapter(forCoin coin: Coin, authData: AuthData) -> IAdapter?
}

protocol ICoinManager: class {
    func enableDefaultCoins()
    var coinsUpdatedSignal: Signal { get }
    var coins: [Coin] { get }
    var allCoins: [Coin] { get }
    func clear()
}

enum AdapterState {
    case synced
    case syncing(progress: Int, lastBlockDate: Date?)
    case notSynced
}

protocol IAdapter: class {
    var coin: Coin { get }
    var feeCoinCode: CoinCode? { get }

    var decimal: Int { get }
    var balance: Decimal { get }
    var balanceUpdatedSignal: Signal { get }

    var state: AdapterState { get }
    var stateUpdatedSignal: Signal { get }

    func transactionsSingle(hashFrom: String?, limit: Int) -> Single<[TransactionRecord]>

    var confirmationsThreshold: Int { get }

    var lastBlockHeight: Int? { get }
    var lastBlockHeightUpdatedSignal: Signal { get }

    var transactionRecordsSubject: PublishSubject<[TransactionRecord]> { get }

    var debugInfo: String { get }

    var refreshable: Bool { get }

    func start()
    func stop()
    func refresh()
    func clear()

    func sendSingle(to address: String, amount: Decimal) -> Single<Void>

    func availableBalance(for address: String?) -> Decimal
    func fee(for value: Decimal, address: String?) -> Decimal
    func validate(address: String) throws
    func validate(amount: Decimal, address: String?) -> [SendStateError]
    func parse(paymentAddress: String) -> PaymentRequestAddress

    var receiveAddress: String { get }
}

extension IAdapter {
    var feeCoinCode: CoinCode? { return nil }
}

protocol IWordsManager {
    var isBackedUp: Bool { get set }
    var backedUpSignal: Signal { get }
    func generateWords() throws -> [String]
    func validate(words: [String]) throws
}

protocol IAuthManager {
    var authData: AuthData? { get }
    var isLoggedIn: Bool { get }
    func login(withWords words: [String], newWallet: Bool) throws
    func logout() throws
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

protocol IPinManager: class {
    var isPinSet: Bool { get }
    func store(pin: String?) throws
    func validate(pin: String) -> Bool
    func clear() throws
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
    func refreshLatestRates(coinCodes: [CoinCode], currencyCode: String)
    func syncZeroValueTimestampRates(currencyCode: String)
    func timestampRateValueObservable(coinCode: CoinCode, currencyCode: String, timestamp: Double) -> Observable<Decimal>
    func clear()
}

protocol IRateSyncerDelegate: class {
    func didSync(coinCode: String, currencyCode: String, latestRate: LatestRate)
}

protocol ISystemInfoManager {
    var appVersion: String { get }
    var biometryType: BiometryType { get }
}

protocol IAppConfigProvider {
    var fiatDecimal: Int { get }
    var maxDecimal: Int { get }
    var reachabilityHost: String { get }
    var apiUrl: String { get }
    var testMode: Bool { get }
    var infuraKey: String { get }
    var etherscanKey: String { get }
    var currencies: [Currency] { get }

    var defaultWords: [String] { get }
    var disablePinLock: Bool { get }
    var defaultCoins: [Coin] { get }
    var erc20Coins: [Coin] { get }
}

protocol IFullTransactionInfoProvider {
    var providerName: String { get }
    func url(for hash: String) -> String

    func retrieveTransactionInfo(transactionHash: String) -> Observable<FullTransactionRecord?>
}

protocol IFullTransactionInfoAdapter {
    func convert(json: [String: Any]) -> FullTransactionRecord?
}

protocol IRateNetworkManager {
    func getLatestRate(coinCode: String, currencyCode: String) -> Observable<LatestRate>
    func getRate(coinCode: String, currencyCode: String, date: Date) -> Observable<Decimal>
}

protocol ITokenNetworkManager {
    func getTokens() -> Observable<[Coin]>
}

protocol IRateStorage {
    func nonExpiredLatestRateValueObservable(forCoinCode coinCode: CoinCode, currencyCode: String) -> Observable<Decimal>
    func latestRateObservable(forCoinCode coinCode: CoinCode, currencyCode: String) -> Observable<Rate>
    func timestampRateObservable(coinCode: CoinCode, currencyCode: String, timestamp: Double) -> Observable<Rate?>
    func zeroValueTimestampRatesObservable(currencyCode: String) -> Observable<[Rate]>
    func save(latestRate: Rate)
    func save(rate: Rate)
    func clearRates()
}

protocol ICoinStorage {
    func enabledCoinsObservable() -> Observable<[Coin]>
    func save(enabledCoins: [Coin])
    func clearCoins()
}

protocol IJSONApiManager {
    func getJSON(url: String, parameters: [String: Any]?) -> Observable<[String: Any]>
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
    var currencies: [Currency] { get }
    var baseCurrency: Currency { get }
    var baseCurrencyUpdatedSignal: Signal { get }

    func setBaseCurrency(code: String)
}

protocol IFullTransactionDataProviderManager {
    var dataProviderUpdatedSignal: Signal { get }

    func providers(for coinCode: String) -> [IProvider]
    func baseProvider(for coinCode: String) -> IProvider
    func setBaseProvider(name: String, for coinCode: String)

    func bitcoin(for name: String) -> IBitcoinForksProvider
    func bitcoinCash(for name: String) -> IBitcoinForksProvider
    func ethereum(for name: String) -> IEthereumForksProvider
}

protocol IPingManager {
    func serverAvailable(url: String, timeoutInterval: TimeInterval) -> Observable<TimeInterval>
}

protocol IBitcoinForksProvider: IProvider {
    func convert(json: [String: Any]) -> IBitcoinResponse?
}

protocol IEthereumForksProvider: IProvider {
    func convert(json: [String: Any]) -> IEthereumResponse?
}

protocol IReachabilityManager {
    var isReachable: Bool { get }
    var reachabilitySignal: Signal { get }
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

protocol IUrlManager {
    func open(url: String, from controller: UIViewController?)
}

protocol IFullTransactionInfoProviderFactory {
    func provider(`for` coinCode: String) -> IFullTransactionInfoProvider
}

protocol ISettingsProviderMap {
    func providers(for coinCode: String) -> [IProvider]
    func bitcoin(for name: String) -> IBitcoinForksProvider
    func bitcoinCash(for name: String) -> IBitcoinForksProvider
    func ethereum(for name: String) -> IEthereumForksProvider
}

protocol IProvider {
    var name: String { get }
    func url(for hash: String) -> String
    func apiUrl(for hash: String) -> String
}

protocol ILockoutManager {
    var currentState: LockoutState { get }
    func didFailUnlock()
    func dropFailedAttempts()
}

protocol ILockoutUntilDateFactory {
    func lockoutUntilDate(failedAttempts: Int, lockoutTimestamp: TimeInterval, uptime: TimeInterval) -> Date
}

protocol ICurrentDateProvider {
    var currentDate: Date { get }
}

protocol IUptimeProvider {
    var uptime: TimeInterval { get }
}

protocol ILockoutTimeFrameFactory {
    func lockoutTimeFrame(failedAttempts: Int, lockoutTimestamp: TimeInterval, uptime: TimeInterval) -> TimeInterval
}
