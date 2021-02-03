import RxSwift
import GRDB
import XRatesKit
import UniswapKit
import EthereumKit
import ThemeKit
import Alamofire
import HsToolKit

typealias CoinCode = String

protocol IRandomManager {
    func getRandomIndexes(max: Int, count: Int) -> [Int]
}

protocol ILocalStorage: class {
    var agreementAccepted: Bool { get set }
    var sortType: SortType? { get set }
    var debugLog: String? { get set }
    var sendInputType: SendInputType? { get set }
    var mainShownOnce: Bool { get set }
    var appVersions: [AppVersion] { get set }
    var transactionDataSortMode: TransactionDataSortMode? { get set }
    var lockTimeEnabled: Bool { get set }
    var appLaunchCount: Int { get set }
    var rateAppLastRequestDate: Date? { get set }
    var balanceHidden: Bool { get set }
    var ethereumRpcMode: EthereumRpcMode? { get set }
    var pushToken: String? { get set }
    var pushNotificationsOn: Bool { get set }
    var marketCategory: Int? { get set }
}

protocol ILogRecordManager {
    func logsGroupedBy(context: String) -> [(String, Any)]
    func onBecomeActive()
}

protocol ILogRecordStorage {
    func logs(context: String) -> [LogRecord]
    func save(logRecord: LogRecord)
    func logsCount() -> Int
    func removeFirstLogs(count: Int)
}

protocol IChartTypeStorage: class {
    var chartType: ChartType? { get set }
}

protocol IAdapterManager: class {
    var adaptersReadyObservable: Observable<Void> { get }
    func adapter(for wallet: Wallet) -> IAdapter?
    func adapter(for coin: Coin) -> IAdapter?
    func balanceAdapter(for wallet: Wallet) -> IBalanceAdapter?
    func transactionsAdapter(for wallet: Wallet) -> ITransactionsAdapter?
    func depositAdapter(for wallet: Wallet) -> IDepositAdapter?
    func refresh()
    func refreshAdapters(wallets: [Wallet])
    func refresh(wallet: Wallet)
}

protocol IAdapterFactory {
    func adapter(wallet: Wallet) -> IAdapter?
}

protocol IWalletManager: class {
    var wallets: [Wallet] { get }
    var walletsUpdatedObservable: Observable<[Wallet]> { get }

    func preloadWallets()

    func save(wallets: [Wallet])

    func delete(wallets: [Wallet])
    func clearWallets()
}

protocol IPriceAlertManager {
    var updateObservable: Observable<[PriceAlert]> { get }
    var priceAlerts: [PriceAlert] { get }
    func priceAlert(coin: Coin) -> PriceAlert
    func save(priceAlerts: [PriceAlert]) -> Observable<[()]>
    func deleteAllAlerts() -> Single<()>
    func updateTopics() -> Observable<[()]>
}

protocol IAdapter: class {
    func start()
    func stop()
    func refresh()

    var debugInfo: String { get }
}

protocol IBalanceAdapter {
    var balanceState: AdapterState { get }
    var balanceStateUpdatedObservable: Observable<Void> { get }
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
    var transactionState: AdapterState { get }
    var transactionStateUpdatedObservable: Observable<Void> { get }
    var lastBlockInfo: LastBlockInfo? { get }
    var lastBlockUpdatedObservable: Observable<Void> { get }
    var transactionRecordsObservable: Observable<[TransactionRecord]> { get }
    func transactionsSingle(from: TransactionRecord?, limit: Int) -> Single<[TransactionRecord]>
    func rawTransaction(hash: String) -> String?
}

protocol ISendBitcoinAdapter {
    var balance: Decimal { get }
    func availableBalance(feeRate: Int, address: String?, pluginData: [UInt8: IBitcoinPluginData]) -> Decimal
    func maximumSendAmount(pluginData: [UInt8: IBitcoinPluginData]) -> Decimal?
    func minimumSendAmount(address: String?) -> Decimal
    func validate(address: String, pluginData: [UInt8: IBitcoinPluginData]) throws
    func fee(amount: Decimal, feeRate: Int, address: String?, pluginData: [UInt8: IBitcoinPluginData]) -> Decimal
    func sendSingle(amount: Decimal, address: String, feeRate: Int, pluginData: [UInt8: IBitcoinPluginData], sortMode: TransactionDataSortMode, logger: Logger) -> Single<Void>
}

protocol ISendDashAdapter {
    func availableBalance(address: String?) -> Decimal
    func minimumSendAmount(address: String?) -> Decimal
    func validate(address: String) throws
    func fee(amount: Decimal, address: String?) -> Decimal
    func sendSingle(amount: Decimal, address: String, sortMode: TransactionDataSortMode, logger: Logger) -> Single<Void>
}

protocol ISendEthereumAdapter {
    var balance: Decimal { get }
    func availableBalance(gasPrice: Int, gasLimit: Int) -> Decimal
    var ethereumBalance: Decimal { get }
    var minimumRequiredBalance: Decimal { get }
    var minimumSpendableAmount: Decimal? { get }
    func validate(address: String) throws
    func estimateGasLimit(to address: String?, value: Decimal, gasPrice: Int?) -> Single<Int>
    func fee(gasPrice: Int, gasLimit: Int) -> Decimal
    func sendSingle(amount: Decimal, address: String, gasPrice: Int, gasLimit: Int, logger: Logger) -> Single<Void>
}

protocol IErc20Adapter {
    var ethereumBalance: Decimal { get }
    var pendingTransactions: [TransactionRecord] { get }
    func fee(gasPrice: Int, gasLimit: Int) -> Decimal
    func allowanceSingle(spenderAddress: EthereumKit.Address, defaultBlockParameter: DefaultBlockParameter) -> Single<Decimal>
}

protocol ISendBinanceAdapter {
    var availableBalance: Decimal { get }
    var availableBinanceBalance: Decimal { get }
    func validate(address: String) throws
    var fee: Decimal { get }
    func sendSingle(amount: Decimal, address: String, memo: String?) -> Single<Void>
}

protocol ISendZcashAdapter {
    var availableBalance: Decimal { get }
    func validate(address: String) throws
    var fee: Decimal { get }
    func sendSingle(amount: Decimal, address: String, memo: String?) -> Single<Void>
}

protocol IWordsManager {
    func generateWords(count: Int) throws -> [String]
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
    var lostAccountsObservable: Observable<Bool> { get }

    func preloadAccounts()
    func update(account: Account)
    func save(account: Account)
    func delete(account: Account)
    func clear()
    func handleLaunch()
    func handleForeground()
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
    func wallet(coin: Coin, account: Account) -> Wallet
}

protocol IBlurManager {
    func willResignActive()
    func didBecomeActive()
}

protocol IRateManager {
    func refresh()

    func convertCoinTypeToXRateKitCoinType(coinType: CoinType) -> XRatesKit.CoinType
    func convertXRateCoinTypeToCoinType(coinType: XRatesKit.CoinType) -> CoinType?

    func marketInfo(coinCode: String, currencyCode: String) -> MarketInfo?
    func globalMarketInfoSingle(currencyCode: String) -> Single<GlobalCoinMarket>
    func topMarketsSingle(currencyCode: String, itemCount: Int) -> Single<[CoinMarket]>
    func coinsMarketSingle(currencyCode: String, coinCodes: [String]) -> Single<[CoinMarket]>
    func marketInfoObservable(coinCode: String, currencyCode: String) -> Observable<MarketInfo>
    func marketInfosObservable(currencyCode: String) -> Observable<[String: MarketInfo]>
    func historicalRate(coinCode: String, currencyCode: String, timestamp: TimeInterval) -> Single<Decimal>
    func historicalRate(coinCode: String, currencyCode: String, timestamp: TimeInterval) -> Decimal?
    func chartInfo(coinCode: String, currencyCode: String, chartType: ChartType) -> ChartInfo?
    func chartInfoObservable(coinCode: String, currencyCode: String, chartType: ChartType) -> Observable<ChartInfo>
}

protocol IFavoritesManager {
    var dataUpdatedObservable: Observable<()> { get }
    var all: [FavoriteCoinRecord] { get }

    func add(coinCode: String)
    func remove(coinCode: String)
    func isFavorite(coinCode: String) -> Bool
}

protocol IPostsManager {
    func posts(timestamp: TimeInterval) -> [CryptoNewsPost]?
    var postsSingle: Single<[CryptoNewsPost]> { get }
}

protocol IRateCoinMapper {
    func convert(coin: Coin) -> Coin?
    func convert(coinCode: String) -> String?
    func unconvert(coinCode: String) -> [String]
}

protocol ISystemInfoManager {
    var appVersion: String { get }
    var passcodeSet: Bool { get }
    var deviceModel: String { get }
    var osVersion: String { get }
}

protocol IAppConfigProvider {
    var companyWebPageLink: String { get }
    var appWebPageLink: String { get }
    var appGitHubLink: String { get }
    var reportEmail: String { get }
    var telegramAccount: String { get }
    var twitterAccount: String { get }
    var redditAccount: String { get }
    var guidesIndexUrl: URL { get }
    var faqIndexUrl: URL { get }
    var uniswapSubgraphUrl: String { get }

    var testMode: Bool { get }
    var officeMode: Bool { get }
    var sandbox: Bool { get }
    var infuraCredentials: (id: String, secret: String?) { get }
    var btcCoreRpcUrl: String { get }
    var etherscanKey: String { get }
    var coinMarketCapApiKey: String { get }
    var cryptoCompareApiKey: String? { get }
    var currencyCodes: [String] { get }
    var feeRateAdjustedForCurrencyCodes: [String] { get }

    var pnsUrl: String { get }
    var pnsPassword: String { get }
    var pnsUsername: String { get }

    func defaultWords(count: Int) -> String

    var ethereumCoin: Coin { get }
    var featuredCoins: [Coin] { get }
    var defaultCoins: [Coin] { get }
    var smartContractFees: [CoinType: Decimal] { get }
    var minimumBalances: [CoinType: Decimal] { get }
    var minimumSpendableAmounts: [CoinType: Decimal] { get }
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
    func lostAccountIds() -> [String]
    func delete(account: Account)
    func delete(accountId: String)
    func clear()
}

protocol IPriceAlertStorage {
    var priceAlerts: [PriceAlert] { get }
    func priceAlert(coin: Coin) -> PriceAlert?
    var activePriceAlerts: [PriceAlert] { get }
    func save(priceAlerts: [PriceAlert])
    func deleteAll()
}

protocol IPriceAlertRecordStorage {
    var priceAlertRecords: [PriceAlertRecord] { get }
    func priceAlertRecord(forCoinId coinCode: String) -> PriceAlertRecord?
    func save(priceAlertRecords: [PriceAlertRecord])
    func deleteAllPriceAlertRecords()
}

protocol IPriceAlertRequestStorage {
    var requests: [PriceAlertRequest] { get }
    func save(requests: [PriceAlertRequest])
    func delete(requests: [PriceAlertRequest])
}

protocol IPriceAlertRequestRecordStorage {
    var priceAlertRequestRecords: [PriceAlertRequestRecord] { get }
    func save(priceAlertRequestRecords: [PriceAlertRequestRecord])
    func delete(priceAlertRequestRecords: [PriceAlertRequestRecord])
}

protocol IBlockchainSettingsRecordStorage {
    func blockchainSettings(coinTypeKey: String, settingKey: String) -> BlockchainSettingRecord?
    func save(blockchainSetting: BlockchainSettingRecord)
    func deleteAll(settingKey: String)
}

protocol IBlockchainSettingsStorage: AnyObject {
    var bitcoinCashCoinType: BitcoinCashCoinType? { get set }

    func derivationSetting(coinType: CoinType) -> DerivationSetting?
    func save(derivationSetting: DerivationSetting)
    func deleteDerivationSettings()

    func initialSyncSetting(coinType: CoinType) -> InitialSyncSetting?
    func save(initialSyncSetting: InitialSyncSetting)
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

protocol IPingManager {
    func serverAvailable(url: String, timeoutInterval: TimeInterval) -> Observable<TimeInterval>
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

protocol ICurrentDateProvider {
    var currentDate: Date { get }
}

protocol IAddressParser {
    func parse(paymentAddress: String) -> AddressData
}

protocol IFeeRateProvider {
    var feeRatePriorityList: [FeeRatePriority] { get }
    var defaultFeeRatePriority: FeeRatePriority { get }
    var recommendedFeeRate: Single<Int> { get }
    func feeRate(priority: FeeRatePriority) -> Single<Int>
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

protocol INotificationManager: AnyObject {
    var token: String? { get }
    func handleLaunch()
    func requestPermission(onComplete: @escaping (Bool) -> ())
    func removeNotifications()
    func didReceivePushToken(tokenData: Data)
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

protocol IRateAppManager {
    func onBalancePageAppear()
    func onBalancePageDisappear()
    func onLaunch()
    func onBecomeActive()
    func onResignActive()
    func forceShow()
}

protocol IRemoteAlertManager {
    var notificationManager: INotificationManager? { get set }

    func handle(requests: [PriceAlertRequest]) -> Observable<[()]>
    func schedule(requests: [PriceAlertRequest])

    func unsubscribeAll() -> Single<()>

    func checkScheduledRequests()
}

protocol IDerivationSettingsManager: AnyObject {
    var allActiveSettings: [(setting: DerivationSetting, coinType: CoinType)] { get }
    func setting(coinType: CoinType) -> DerivationSetting?
    func save(setting: DerivationSetting)
    func resetStandardSettings()
}

protocol IInitialSyncSettingsManager: AnyObject {
    var allSettings: [(setting: InitialSyncSetting, coin: Coin, changeable: Bool)] { get }
    func setting(coinType: CoinType, accountOrigin: AccountOrigin) -> InitialSyncSetting?
    func save(setting: InitialSyncSetting)
}

protocol IEthereumRpcModeSettingsManager: AnyObject {
    var rpcMode: EthereumRpcMode { get }
    func save(rpcMode: EthereumRpcMode)
}

protocol ITransactionDataSortModeSettingManager {
    var setting: TransactionDataSortMode { get }
    func save(setting: TransactionDataSortMode)
}

protocol ISortTypeManager: AnyObject {
    var sortType: SortType { get set }
    var sortTypeObservable: Observable<SortType> { get }
}

protocol IGuidesManager {
    func guideCategoriesSingle(url: URL) -> Single<[GuideCategory]>
}

protocol IErc20ContractInfoProvider {
    func coinSingle(address: String) -> Single<Coin>
}

protocol ICoinManager {
    var coinAddedObservable: Observable<Coin> { get }
    var coins: [Coin] { get }
    var featuredCoins: [Coin] { get }
    func save(coin: Coin)
}

protocol ICoinRecordStorage {
    var coinRecords: [CoinRecord] { get }
    func save(coinRecord: CoinRecord)
}

protocol ICoinStorage {
    var coins: [Coin] { get }
    func save(coin: Coin) -> Bool
}

protocol IFavoriteCoinRecordStorage {
    var favoriteCoinRecords: [FavoriteCoinRecord] { get }
    func save(coinCode: String)
    func deleteFavoriteCoinRecord(coinCode: String)
    func inFavorites(coinCode: String) -> Bool
}

protocol ITermsManager {
    var terms: [Term] { get }
    var termsAccepted: Bool { get }
    var termsAcceptedObservable: Observable<Bool> { get }
    func update(term: Term)
}

protocol IPresentDelegate: AnyObject {
    func show(viewController: UIViewController)
}
