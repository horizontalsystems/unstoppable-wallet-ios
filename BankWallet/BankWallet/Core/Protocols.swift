import RxSwift
import GRDB
import XRatesKit
import ThemeKit

typealias CoinCode = String

protocol IRandomManager {
    func getRandomIndexes(max: Int, count: Int) -> [Int]
}

protocol ILocalStorage: class {
    var baseCurrencyCode: String? { get set }
    var baseBitcoinProvider: String? { get set }
    var baseBitcoinCashProvider: String? { get set }
    var baseDashProvider: String? { get set }
    var baseBinanceProvider: String? { get set }
    var baseEosProvider: String? { get set }
    var baseEthereumProvider: String? { get set }
    var lightMode: Bool { get set }
    var agreementAccepted: Bool { get set }
    var balanceSortType: BalanceSortType? { get set }
    var isBiometricOn: Bool { get set }
    var currentLanguage: String? { get set }
    var debugLog: String? { get set }
    var lastExitDate: Double { get set }
    var didLaunchOnce: Bool { get set }
    var sendInputType: SendInputType? { get set }
    var mainShownOnce: Bool { get set }
    var appVersions: [AppVersion] { get set }
    var lockTimeEnabled: Bool { get set }
    var bitcoinDerivation: MnemonicDerivation? { get set }
    var syncMode: SyncMode? { get set }
}

protocol IChartTypeStorage: class {
    var chartType: ChartType? { get set }
}

protocol ISecureStorage: class {
    var pin: String? { get }
    func set(pin: String?) throws
    var unlockAttempts: Int? { get }
    func set(unlockAttempts: Int?) throws
    var lockoutTimestamp: TimeInterval? { get }
    func set(lockoutTimestamp: TimeInterval?) throws

    func getString(forKey key: String) -> String?
    func set(value: String?, forKey key: String) throws
    func getData(forKey key: String) -> Data?
    func set(value: Data?, forKey key: String) throws
    func remove(for key: String) throws

    func clear() throws
}

protocol IAdapterManager: class {
    var adaptersReadyObservable: Observable<Void> { get }
    func adapter(for wallet: Wallet) -> IAdapter?
    func balanceAdapter(for wallet: Wallet) -> IBalanceAdapter?
    func transactionsAdapter(for wallet: Wallet) -> ITransactionsAdapter?
    func depositAdapter(for wallet: Wallet) -> IDepositAdapter?
    func refresh()
}

protocol IAdapterFactory {
    func adapter(wallet: Wallet) -> IAdapter?
}

protocol IWalletManager: class {
    var wallets: [Wallet] { get }
    var walletsUpdatedObservable: Observable<[Wallet]> { get }

    func preloadWallets()

    func save(wallets: [Wallet])

    func update(derivation: MnemonicDerivation, in wallets: [Wallet])
    func update(syncMode: SyncMode, in wallets: [Wallet])

    func delete(wallets: [Wallet])
    func clearWallets()
}

protocol IPriceAlertManager {
    var priceAlerts: [PriceAlert] { get }
    func save(priceAlerts: [PriceAlert])
}

protocol IAdapter: class {
    func start()
    func stop()
    func refresh()

    var debugInfo: String { get }
}

protocol IBalanceAdapter {
    var state: AdapterState { get }
    var stateUpdatedObservable: Observable<Void> { get }
    var balance: Decimal { get }
    var balanceLocked: Decimal? { get }
    var balanceUpdatedObservable: Observable<Void> { get }
}

extension IBalanceAdapter {
    var balanceLocked: Decimal? { nil }
}

protocol IDepositAdapter {
    var receiveAddress: String { get }
}

protocol ITransactionsAdapter {
    var confirmationsThreshold: Int { get }
    var lastBlockInfo: LastBlockInfo? { get }
    var lastBlockUpdatedObservable: Observable<Void> { get }
    var transactionRecordsObservable: Observable<[TransactionRecord]> { get }
    func transactionsSingle(from: TransactionRecord?, limit: Int) -> Single<[TransactionRecord]>
}

protocol ISendBitcoinAdapter {
    func availableBalance(feeRate: Int, address: String?, pluginData: [UInt8: IBitcoinPluginData]) -> Decimal
    func maximumSendAmount(pluginData: [UInt8: IBitcoinPluginData]) -> Decimal?
    func minimumSendAmount(address: String?) -> Decimal
    func validate(address: String, pluginData: [UInt8: IBitcoinPluginData]) throws
    func fee(amount: Decimal, feeRate: Int, address: String?, pluginData: [UInt8: IBitcoinPluginData]) -> Decimal
    func sendSingle(amount: Decimal, address: String, feeRate: Int, pluginData: [UInt8: IBitcoinPluginData]) -> Single<Void>
}

protocol ISendDashAdapter {
    func availableBalance(address: String?) -> Decimal
    func minimumSendAmount(address: String?) -> Decimal
    func validate(address: String) throws
    func fee(amount: Decimal, address: String?) -> Decimal
    func sendSingle(amount: Decimal, address: String) -> Single<Void>
}

protocol ISendEthereumAdapter {
    func availableBalance(gasPrice: Int, gasLimit: Int?) -> Decimal
    var ethereumBalance: Decimal { get }
    var minimumRequiredBalance: Decimal { get }
    var minimumSpendableAmount: Decimal? { get }
    func validate(address: String) throws
    func estimateGasLimit(to address: String, value: Decimal, gasPrice: Int?) -> Single<Int>
    func fee(gasPrice: Int, gasLimit: Int) -> Decimal
    func sendSingle(amount: Decimal, address: String, gasPrice: Int, gasLimit: Int) -> Single<Void>
}

protocol ISendEosAdapter {
    var availableBalance: Decimal { get }
    func validate(account: String) throws
    func sendSingle(amount: Decimal, account: String, memo: String?) -> Single<Void>
}

protocol ISendBinanceAdapter {
    var availableBalance: Decimal { get }
    var availableBinanceBalance: Decimal { get }
    func validate(address: String) throws
    var fee: Decimal { get }
    func sendSingle(amount: Decimal, address: String, memo: String?) -> Single<Void>
}

protocol IWordsManager {
    func generateWords(count: Int) throws -> [String]
    func validate(words: [String], requiredWordsCount: Int) throws
}

protocol IAuthManager {
    func login(withWords words: [String], syncMode: SyncMode) throws
    func logout() throws
}

protocol IAccountManager {
    var accounts: [Account] { get }
    func account(coinType: CoinType) -> Account?

    var accountsObservable: Observable<[Account]> { get }
    var deleteAccountObservable: Observable<Account> { get }

    func preloadAccounts()
    func update(account: Account)
    func save(account: Account)
    func delete(account: Account)
    func clear()
}

protocol IBackupManager {
    var allBackedUp: Bool { get }
    var allBackedUpObservable: Observable<Bool> { get }
    func setAccountBackedUp(id: String)
}

protocol IAccountCreator {
    func newAccount(predefinedAccountType: PredefinedAccountType) throws -> Account
    func restoredAccount(accountType: AccountType) -> Account
}

protocol IAccountFactory {
    func account(type: AccountType, origin: AccountOrigin, backedUp: Bool) -> Account
}

protocol IWalletFactory {
    func wallet(coin: Coin, account: Account, coinSettings: CoinSettings) -> Wallet
}

protocol IRestoreAccountDataSource {
    var restoreAccounts: [Account] { get }
}

protocol ILockManager {
    var isLocked: Bool { get }
    func lock()
    func didEnterBackground()
    func willEnterForeground()
}

protocol IPasscodeLockManager {
    var locked: Bool { get }
    func didFinishLaunching()
    func willEnterForeground()
}

protocol IBlurManager {
    func willResignActive()
    func didBecomeActive()
}

protocol IPinManager: class {
    var isPinSet: Bool { get }
    var biometryEnabled: Bool { get set }
    func store(pin: String) throws
    func validate(pin: String) -> Bool
    func clear() throws

    var isPinSetObservable: Observable<Bool> { get }
}

protocol ILockRouter {
    func showUnlock(delegate: IUnlockDelegate)
}

protocol IPasscodeLockRouter {
    func showNoPasscode()
    func showLaunch()
}

protocol IBiometricManager {
    func validate(reason: String)
}

protocol BiometricManagerDelegate: class {
    func didValidate()
    func didFailToValidate()
}

protocol IRateManager {
    func refresh()
    func marketInfo(coinCode: String, currencyCode: String) -> MarketInfo?
    func marketInfoObservable(coinCode: String, currencyCode: String) -> Observable<MarketInfo>
    func marketInfosObservable(currencyCode: String) -> Observable<[String: MarketInfo]>
    func historicalRate(coinCode: String, currencyCode: String, timestamp: TimeInterval) -> Single<Decimal>
    func chartInfo(coinCode: String, currencyCode: String, chartType: ChartType) -> ChartInfo?
    func chartInfoObservable(coinCode: String, currencyCode: String, chartType: ChartType) -> Observable<ChartInfo>
}

protocol IRateCoinMapper {
    var convertCoinMap: [String: String] { get }
    var unconvertCoinMap: [String: String] { get }

    func addCoin(direction: RateDirectionMap, from: String, to: String?)
}

protocol IBlockedChartCoins {
    var blockedCoins: Set<String> { get }
}

protocol ISystemInfoManager {
    var appVersion: String { get }
    var biometryType: Single<BiometryType> { get }
    var passcodeSet: Bool { get }
    var deviceModel: String { get }
    var osVersion: String { get }
}

protocol IBiometryManager {
    var biometryType: BiometryType { get }
    var biometryTypeObservable: Observable<BiometryType> { get }
    func refresh()
}

protocol IAppConfigProvider {
    var ipfsId: String { get }
    var ipfsGateways: [String] { get }

    var companyWebPageLink: String { get }
    var appWebPageLink: String { get }
    var reportEmail: String { get }
    var telegramWalletHelperGroup: String { get }
    var telegramDevelopersGroup: String { get }

    var reachabilityHost: String { get }
    var testMode: Bool { get }
    var officeMode: Bool { get }
    var infuraCredentials: (id: String, secret: String?) { get }
    var btcCoreRpcUrl: String { get }
    var etherscanKey: String { get }
    var currencies: [Currency] { get }

    func defaultWords(count: Int) -> [String]
    var defaultEosCredentials: (String, String) { get }
    var disablePinLock: Bool { get }

    var featuredCoins: [Coin] { get }
    var coins: [Coin] { get }
}

protocol IFullTransactionInfoProvider {
    var providerName: String { get }
    func url(for hash: String) -> String?

    func retrieveTransactionInfo(transactionHash: String) -> Single<FullTransactionRecord?>
}

protocol IFullTransactionInfoAdapter {
    func convert(json: [String: Any]) -> FullTransactionRecord?
}

protocol IIpfsApiProvider {
    func gatewaysSingle<T>(singleProvider: @escaping (String, TimeInterval) -> Single<T>) -> Single<T>
}

protocol IEnabledWalletStorage {
    var enabledWallets: [EnabledWallet] { get }
    func save(enabledWallets: [EnabledWallet])
    func delete(enabledWallets: [EnabledWallet])
    func clearEnabledWallets()
}

protocol IAccountStorage {
    var allAccounts: [Account] { get }
    func save(account: Account)
    func delete(account: Account)
    func clear()
}

protocol IPriceAlertStorage {
    var priceAlerts: [PriceAlert] { get }
    var activePriceAlerts: [PriceAlert] { get }
    func save(priceAlerts: [PriceAlert])
    func delete(priceAlerts: [PriceAlert])
    func deleteExcluding(coinCodes: [CoinCode])
}

protocol IPriceAlertRecordStorage {
    var priceAlertRecords: [PriceAlertRecord] { get }
    func save(priceAlertRecords: [PriceAlertRecord])
    func deletePriceAlertRecords(coinCodes: [CoinCode])
    func deletePriceAlertsExcluding(coinCodes: [CoinCode])
}

protocol IBackgroundPriceAlertManager {
    func didEnterBackground()
    func fetchRates(onComplete: @escaping (Bool) -> ())
}

protocol IPriceAlertHandler {
//    func handleAlerts(with latestRatesData: LatestRateData)
}

protocol INotificationFactory {
    func notifications(forAlerts alertItems: [PriceAlertItem]) -> [AlertNotification]
}

protocol IEmojiHelper {
    var multiAlerts: String { get }
    func title(forState state: Int) -> String
    func body(forState state: Int) -> String
}

protocol IKitCleaner {
    func clear()
}

protocol IAccountRecordStorage {
    var allAccountRecords: [AccountRecord] { get }
    func save(accountRecord: AccountRecord)
    func deleteAccountRecord(by id: String)
    func deleteAllAccountRecords()
}

protocol IJsonApiProvider {
    func getJson(requestObject: JsonApiProvider.RequestObject) -> Single<[String: Any]>
}

protocol ITransactionRecordStorage {
    func record(forHash hash: String) -> TransactionRecord?
    var nonFilledRecords: [TransactionRecord] { get }
    func set(rate: Double, transactionHash: String)
    func clearRates()

    func update(records: [TransactionRecord])
    func clearRecords()
}

protocol ICurrencyManager: AnyObject {
    var baseCurrency: Currency { get set }
    var currencies: [Currency] { get }
    var baseCurrencyUpdatedSignal: Signal { get }
}

protocol IFullTransactionDataProviderManager {
    var dataProviderUpdatedSignal: Signal { get }

    func providers(for coin: Coin) -> [IProvider]
    func baseProvider(for coin: Coin) -> IProvider
    func setBaseProvider(name: String, for coin: Coin)

    func bitcoin(for name: String) -> IBitcoinForksProvider
    func dash(for name: String) -> IBitcoinForksProvider
    func eos(for name: String) -> IEosProvider
    func bitcoinCash(for name: String) -> IBitcoinForksProvider
    func ethereum(for name: String) -> IEthereumForksProvider
    func binance(for name: String) -> IBinanceProvider
}

protocol IPingManager {
    func serverAvailable(url: String, timeoutInterval: TimeInterval) -> Observable<TimeInterval>
}

protocol IEosProvider: IProvider {
    func convert(json: [String: Any], account: String) -> IEosResponse?
}

protocol IBitcoinForksProvider: IProvider {
    func convert(json: [String: Any]) -> IBitcoinResponse?
}

protocol IEthereumForksProvider: IProvider {
    func convert(json: [String: Any]) -> IEthereumResponse?
}

protocol IBinanceProvider: IProvider {
    func convert(json: [String: Any]) -> IBinanceResponse?
}

protocol IReachabilityManager {
    var isReachable: Bool { get }
    var reachabilitySignal: Signal { get }
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
    func provider(`for` wallet: Wallet) -> IFullTransactionInfoProvider
}

protocol ISettingsProviderMap {
    func providers(for coinCode: String) -> [IProvider]
    func bitcoin(for name: String) -> IBitcoinForksProvider
    func bitcoinCash(for name: String) -> IBitcoinForksProvider
    func ethereum(for name: String) -> IEthereumForksProvider
}

protocol IProvider {
    var name: String { get }
    var reachabilityUrl: String { get }
    func url(for hash: String) -> String?
    func requestObject(for hash: String) -> JsonApiProvider.RequestObject
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
    func feeRate(for priority: FeeRatePriority) -> Single<FeeRate>
}

protocol IEncryptionManager {
    func encrypt(data: Data) throws -> Data
    func decrypt(data: Data) throws -> Data
}

protocol IUUIDProvider {
    func generate() -> String
}

protocol IPredefinedAccountTypeManager {
    var allTypes: [PredefinedAccountType] { get }
    func account(predefinedAccountType: PredefinedAccountType) -> Account?
    func predefinedAccountType(accountType: AccountType) -> PredefinedAccountType?
}

protocol IAppManager {
    var didBecomeActiveObservable: Observable<()> { get }
    var willEnterForegroundObservable: Observable<()> { get }
}

protocol IWalletStorage {
    func wallets(accounts: [Account]) -> [Wallet]
    func save(wallets: [Wallet])
    func delete(wallets: [Wallet])
    func clearWallets()
}

protocol IDefaultWalletCreator {
    func createWallets(account: Account)
    func createWallet(account: Account, coin: Coin)
}

protocol IFeeCoinProvider {
    func feeCoin(coin: Coin) -> Coin?
    func feeCoinProtocol(coin: Coin) -> String?
}

protocol INotificationManager {
    var allowedBackgroundFetching: Bool { get }
    func requestPermission(onComplete: @escaping (Bool) -> ())
    func show(notification: AlertNotification)
    func removeNotifications()
}

protocol IDebugLogger {
    var logs: [String] { get }

    func logFinishLaunching()
    func logEnterBackground()
    func logEnterForeground()
    func logTerminate()

    func add(log: String)
    func clearLogs()
}

protocol IAppStatusManager {
    var status: [(String, Any)] { get }
}

protocol IAppVersionManager {
    func checkLatestVersion()
}
