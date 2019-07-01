import RxSwift
import BitcoinCore

typealias CoinCode = String

protocol IRandomManager {
    func getRandomIndexes(count: Int) -> [Int]
}

protocol ILocalStorage: class {
    var syncMode: SyncMode? { get set }
    var isBackedUp: Bool { get set }
    var baseCurrencyCode: String? { get set }
    var baseBitcoinProvider: String? { get set }
    var baseDashProvider: String? { get set }
    var baseEthereumProvider: String? { get set }
    var lightMode: Bool { get set }
    var agreementAccepted: Bool { get set }
    var balanceSortType: BalanceSortType? { get set }
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
    func refresh()
}

protocol IAdapterFactory {
    func adapter(wallet: Wallet) -> IAdapter?
}

protocol IWalletManager: class {
    var wallets: [Wallet] { get }
    var walletsUpdatedSignal: Signal { get }
    func enable(wallets: [Wallet])
    func enableDefaultWallets()
}

enum AdapterState {
    case synced
    case syncing(progress: Int, lastBlockDate: Date?)
    case notSynced
}

enum SyncMode: String {
    case fast = "fast"
    case slow = "slow"
    case new = "new"
}

enum FeeRatePriority: Int {
    case lowest
    case low
    case medium
    case high
    case highest
}

protocol IAdapter: class {
    var wallet: Wallet { get }
    var feeCoinCode: CoinCode? { get }

    var decimal: Int { get }
    var confirmationsThreshold: Int { get }

    func start()
    func stop()
    func refresh()

    var lastBlockHeight: Int? { get }
    var lastBlockHeightUpdatedObservable: Observable<Void> { get }

    var state: AdapterState { get }
    var stateUpdatedObservable: Observable<Void> { get }

    var balance: Decimal { get }
    var balanceUpdatedObservable: Observable<Void> { get }

    var transactionRecordsObservable: Observable<[TransactionRecord]> { get }
    func transactionsSingle(from: (hash: String, interTransactionIndex: Int)?, limit: Int) -> Single<[TransactionRecord]>

    func sendSingle(to address: String, amount: Decimal, feeRatePriority: FeeRatePriority) -> Single<Void>

    func availableBalance(for address: String?, feeRatePriority: FeeRatePriority) -> Decimal
    func fee(for value: Decimal, address: String?, feeRatePriority: FeeRatePriority) -> Decimal
    func validate(address: String) throws
    func validate(amount: Decimal, address: String?, feeRatePriority: FeeRatePriority) -> [SendStateError]
    func parse(paymentAddress: String) -> PaymentRequestAddress

    var receiveAddress: String { get }

    var debugInfo: String { get }
}

extension IAdapter {
    var feeCoinCode: CoinCode? { return nil }
}

enum SendTransactionError: LocalizedError {
    case connection
    case unknown

    public var errorDescription: String? {
        switch self {
        case .connection: return "alert.no_internet".localized
        case .unknown: return "alert.network_issue".localized
        }
    }

}

protocol IWordsManager {
    var isBackedUp: Bool { get set }
    var backedUpSignal: Signal { get }
    func generateWords() throws -> [String]
    func validate(words: [String]) throws
}

protocol IAuthManager {
    var authData: AuthData? { get }
    func login(withWords words: [String], syncMode: SyncMode) throws
    func logout() throws
}

protocol IAccountManager {
    var accounts: [Account] { get }
    var accountsObservable: Observable<[Account]> { get }

    func save(account: Account)
    func deleteAccount(id: String)
    func setAccountBackedUp(id: String)
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
    func timestampRateValueObservable(coinCode: CoinCode, currencyCode: String, date: Date) -> Single<Decimal>
    func clear()
}

protocol ISystemInfoManager {
    var appVersion: String { get }
    var biometryType: Single<BiometryType> { get }
}

protocol IAppConfigProvider {
    var ipfsId: String { get }
    var ipfsGateways: [String] { get }

    var fiatDecimal: Int { get }
    var maxDecimal: Int { get }
    var reachabilityHost: String { get }
    var testMode: Bool { get }
    var infuraCredentials: (id: String, secret: String?) { get }
    var etherscanKey: String { get }
    var currencies: [Currency] { get }

    var defaultWords: [String] { get }
    var disablePinLock: Bool { get }

    var defaultCoinCodes: [CoinCode] { get }
    var coins: [Coin] { get }
}

protocol IFullTransactionInfoProvider {
    var providerName: String { get }
    func url(for hash: String) -> String

    func retrieveTransactionInfo(transactionHash: String) -> Single<FullTransactionRecord?>
}

protocol IFullTransactionInfoAdapter {
    func convert(json: [String: Any]) -> FullTransactionRecord?
}

protocol IRateApiProvider {
    func getLatestRateData(currencyCode: String) -> Single<LatestRateData>
    func getRate(coinCode: String, currencyCode: String, date: Date) -> Single<Decimal>
}

protocol IRateStorage {
    func nonExpiredLatestRateObservable(forCoinCode coinCode: CoinCode, currencyCode: String) -> Observable<Rate?>
    func latestRateObservable(forCoinCode coinCode: CoinCode, currencyCode: String) -> Observable<Rate>
    func timestampRateObservable(coinCode: CoinCode, currencyCode: String, date: Date) -> Observable<Rate?>
    func zeroValueTimestampRatesObservable(currencyCode: String) -> Observable<[Rate]>
    func save(latestRate: Rate)
    func save(rate: Rate)
    func clearRates()
}

protocol IEnabledWalletStorage {
    var enabledWallets: [EnabledWallet] { get }
    func save(enabledWallets: [EnabledWallet])
}

protocol IJsonApiProvider {
    func getJson(urlString: String, parameters: [String: Any]?) -> Single<[String: Any]>
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

    func providers(for coin: Coin) -> [IProvider]
    func baseProvider(for coin: Coin) -> IProvider
    func setBaseProvider(name: String, for coin: Coin)

    func bitcoin(for name: String) -> IBitcoinForksProvider
    func dash(for name: String) -> IBitcoinForksProvider
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
    func provider(`for` coin: Coin) -> IFullTransactionInfoProvider
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

protocol IAddressParser {
    func parse(paymentAddress: String) -> AddressData
}

protocol IFeeRateProvider {
    func ethereumGasPrice(for priority: FeeRatePriority) -> Int
    func bitcoinFeeRate(for priority: FeeRatePriority) -> Int
    func bitcoinCashFeeRate(for priority: FeeRatePriority) -> Int
    func dashFeeRate(for priority: FeeRatePriority) -> Int
}

enum AdapterError: Error {
    case unsupportedAccount
}
