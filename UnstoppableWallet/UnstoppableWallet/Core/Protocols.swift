import Foundation
import RxSwift
import GRDB
import XRatesKit
import UniswapKit
import EthereumKit
import ThemeKit
import Alamofire
import HsToolKit
import CoinKit
import BigInt

typealias CoinCode = String

protocol IRandomManager {
    func getRandomIndexes(max: Int, count: Int) -> [Int]
}

protocol ILocalStorage: AnyObject {
    var agreementAccepted: Bool { get set }
    var sortType: SortType? { get set }
    var debugLog: String? { get set }
    var sendInputType: SendInputType? { get set }
    var mainShownOnce: Bool { get set }
    var jailbreakShownOnce: Bool { get set }
    var transactionDataSortMode: TransactionDataSortMode? { get set }
    var lockTimeEnabled: Bool { get set }
    var appLaunchCount: Int { get set }
    var rateAppLastRequestDate: Date? { get set }
    var balanceHidden: Bool { get set }
    var pushToken: String? { get set }
    var pushNotificationsOn: Bool { get set }
    var marketCategory: Int? { get set }
    var zcashAlwaysPendingRewind: Bool { get set }

    func defaultProvider(blockchain: SwapModule.Dex.Blockchain) -> SwapModule.Dex.Provider
    func setDefaultProvider(blockchain: SwapModule.Dex.Blockchain, provider: SwapModule.Dex.Provider)
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

protocol IChartTypeStorage: AnyObject {
    var chartType: ChartType? { get set }
}

protocol IPriceAlertManager {
    var updateObservable: Observable<[PriceAlert]> { get }
    var priceAlerts: [PriceAlert] { get }
    func priceAlert(coinType: CoinType, title: String) -> PriceAlert?
    func save(priceAlerts: [PriceAlert]) -> Observable<[()]>
    func deleteAllAlerts() -> Single<()>
    func updateTopics() -> Observable<[()]>
}

protocol IBaseAdapter {
    var isMainNet: Bool { get }
}

protocol IAdapter: AnyObject {
    func start()
    func stop()
    func refresh()

    var statusInfo: [(String, Any)] { get }
    var debugInfo: String { get }
}

protocol IBalanceAdapter: IBaseAdapter {
    var balanceState: AdapterState { get }
    var balanceStateUpdatedObservable: Observable<AdapterState> { get }
    var balanceData: BalanceData { get }
    var balanceDataUpdatedObservable: Observable<BalanceData> { get }
}

protocol IDepositAdapter: IBaseAdapter {
    var receiveAddress: String { get }
}

protocol ITransactionsAdapter {
    var transactionState: AdapterState { get }
    var transactionStateUpdatedObservable: Observable<Void> { get }
    var lastBlockInfo: LastBlockInfo? { get }
    var lastBlockUpdatedObservable: Observable<Void> { get }
    func transactionsObservable(coin: Coin?) -> Observable<[TransactionRecord]>
    func transactionsSingle(from: TransactionRecord?, coin: Coin?, limit: Int) -> Single<[TransactionRecord]>
    func rawTransaction(hash: String) -> String?
}

protocol ISendBitcoinAdapter {
    var balanceData: BalanceData { get }
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
    var evmKit: EthereumKit.Kit { get }
    var balanceData: BalanceData { get }
    func transactionData(amount: BigUInt, address: EthereumKit.Address) -> TransactionData
}

protocol IErc20Adapter {
    var pendingTransactions: [TransactionRecord] { get }
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
    func validate(address: String) throws -> ZcashAdapter.AddressType
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
    var activeAccount: Account? { get }
    func set(activeAccountId: String?)

    var accounts: [Account] { get }
    func account(id: String) -> Account?

    var activeAccountObservable: Observable<Account?> { get }
    var accountsObservable: Observable<[Account]> { get }
    var accountUpdatedObservable: Observable<Account> { get }
    var accountDeletedObservable: Observable<Account> { get }
    var accountsLostObservable: Observable<Bool> { get }

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

protocol IBlurManager {
    func willResignActive()
    func didBecomeActive()
}

protocol IRateManager {
    func refresh(currencyCode: String)

    func globalMarketInfoSingle(currencyCode: String, period: TimePeriod) -> Single<GlobalCoinMarket>
    func topMarketsSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, itemCount: Int) -> Single<[CoinMarket]>
    func coinsMarketSingle(currencyCode: String, coinTypes: [CoinType]) -> Single<[CoinMarket]>
    func searchCoins(text: String) -> [CoinData]
    func latestRate(coinType: CoinType, currencyCode: String) -> LatestRate?
    func latestRateMap(coinTypes: [CoinType], currencyCode: String) -> [CoinType: LatestRate]
    func latestRateObservable(coinType: CoinType, currencyCode: String) -> Observable<LatestRate>
    func latestRatesObservable(coinTypes: [CoinType], currencyCode: String) -> Observable<[CoinType: LatestRate]>
    func historicalRate(coinType: CoinType, currencyCode: String, timestamp: TimeInterval) -> Single<Decimal>
    func historicalRate(coinType: CoinType, currencyCode: String, timestamp: TimeInterval) -> Decimal?
    func chartInfo(coinType: CoinType, currencyCode: String, chartType: ChartType) -> ChartInfo?
    func chartInfoObservable(coinType: CoinType, currencyCode: String, chartType: ChartType) -> Observable<ChartInfo>
    func coinMarketInfoSingle(coinType: CoinType, currencyCode: String, rateDiffTimePeriods: [TimePeriod], rateDiffCoinCodes: [String]) -> Single<CoinMarketInfo>
    func globalMarketInfoPointsSingle(currencyCode: String, timePeriod: TimePeriod) -> Single<[GlobalCoinMarketPoint]>
    func topDefiTvlSingle(currencyCode: String, fetchDiffPeriod: TimePeriod, itemsCount: Int, chain: String?) -> Single<[DefiTvl]>
    func defiTvlPoints(coinType: CoinType, currencyCode: String, fetchDiffPeriod: TimePeriod) -> Single<[DefiTvlPoint]>
    func defiTvl(coinType: CoinType, currencyCode: String) -> Single<DefiTvl?>
    func coinMarketPointsSingle(coinType: CoinType, currencyCode: String, fetchDiffPeriod: TimePeriod) -> Single<[CoinMarketPoint]>
    func topTokenHoldersSingle(coinType: CoinType, itemsCount: Int) -> Single<[TokenHolder]>
    func auditReportsSingle(coinType: CoinType) -> Single<[Auditor]>
    func coinTypes(for category: String) -> [CoinType]
}

protocol IFavoritesManager {
    var dataUpdatedObservable: Observable<()> { get }
    var all: [FavoriteCoinRecord] { get }

    func add(coinType: CoinType)
    func remove(coinType: CoinType)
    func isFavorite(coinType: CoinType) -> Bool
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
    var appVersion: AppVersion { get }
    var passcodeSet: Bool { get }
    var deviceModel: String { get }
    var osVersion: String { get }
}

protocol IAppConfigProvider {
    var companyWebPageLink: String { get }
    var appWebPageLink: String { get }
    var appGitHubLink: String { get }
    var reportEmail: String { get }
    var guidesIndexUrl: URL { get }
    var faqIndexUrl: URL { get }
    var uniswapSubgraphUrl: String { get }
    var providerCoinsUrl: String { get }
    var coinsUrl: String { get }

    var testMode: Bool { get }
    var officeMode: Bool { get }
    var sandbox: Bool { get }
    var infuraCredentials: (id: String, secret: String?) { get }
    var btcCoreRpcUrl: String { get }
    var etherscanKey: String { get }
    var bscscanKey: String { get }
    var coinMarketCapApiKey: String { get }
    var cryptoCompareApiKey: String? { get }
    var defiYieldApiKey: String? { get }
    var currencyCodes: [String] { get }
    var feeRateAdjustedForCurrencyCodes: [String] { get }

    var pnsUrl: String { get }

    var featuredCoinTypes: [CoinType] { get }
    func defaultWords(count: Int) -> String

    var defaultWords: String { get }
}

protocol ICoinMigration {
    var coinMigrationObservable: Observable<[Coin]> { get }
}

protocol IEnabledWalletStorage {
    var enabledWallets: [EnabledWallet] { get }
    func enabledWallets(accountId: String) -> [EnabledWallet]
    func handle(newEnabledWallets: [EnabledWallet], deletedEnabledWallets: [EnabledWallet])
    func clearEnabledWallets()
}

protocol IActiveAccountStorage: AnyObject {
    var activeAccountId: String? { get set }
}

protocol IPriceAlertStorage {
    var priceAlerts: [PriceAlert] { get }
    func priceAlert(coinType: CoinType) -> PriceAlert?
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

protocol IAppVersionStorage {
    var appVersions: [AppVersion] { get }
    func save(appVersions: [AppVersion])
}

protocol IAppVersionRecordStorage {
    var appVersionRecords: [AppVersionRecord] { get }
    func save(appVersionRecords: [AppVersionRecord])
}

protocol IBlockchainSettingsRecordStorage {
    func blockchainSettings(coinTypeKey: String, settingKey: String) -> BlockchainSettingRecord?
    func save(blockchainSetting: BlockchainSettingRecord)
    func deleteAll(settingKey: String)
}

protocol IBlockchainSettingsStorage: AnyObject {
    func initialSyncSetting(coinType: CoinType) -> InitialSyncSetting?
    func save(initialSyncSetting: InitialSyncSetting)
}

protocol IRestoreSettingsStorage {
    func restoreSettings(accountId: String, coinId: String) -> [RestoreSettingRecord]
    func restoreSettings(accountId: String) -> [RestoreSettingRecord]
    func save(restoreSettingRecords: [RestoreSettingRecord])
    func deleteAllRestoreSettings(accountId: String)
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

protocol ICustomRangedFeeRateProvider: IFeeRateProvider {
    var customFeeRange: ClosedRange<Int> { get }
}

protocol IEncryptionManager {
    func encrypt(data: Data) throws -> Data
    func decrypt(data: Data) throws -> Data
}

protocol IUUIDProvider {
    func generate() -> String
}

protocol IAppManager {
    var didBecomeActiveObservable: Observable<()> { get }
    var willEnterForegroundObservable: Observable<()> { get }
}

protocol IWalletStorage {
    func wallets(accounts: [Account]) -> [Wallet]
    func wallets(account: Account) -> [Wallet]
    func handle(newWallets: [Wallet], deletedWallets: [Wallet])
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
    var newVersionObservable: Observable<AppVersion?> { get }
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

protocol IInitialSyncSettingsManager: AnyObject {
    var allSettings: [(setting: InitialSyncSetting, coin: Coin, changeable: Bool)] { get }
    func setting(coinType: CoinType, accountOrigin: AccountOrigin) -> InitialSyncSetting?
    func save(setting: InitialSyncSetting)
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
    var coinsAddedObservable: Observable<[Coin]> { get }
    var coins: [Coin] { get }
    var groupedCoins: (featured: [Coin], regular: [Coin]) { get }
    func coin(type: CoinType) -> Coin?
    func coinOrStub(type: CoinType) -> Coin
    func save(coins: [Coin])
}

protocol IFavoriteCoinRecordStorage {
    var favoriteCoinRecords: [FavoriteCoinRecord] { get }
    func save(coinType: CoinType)
    func deleteFavoriteCoinRecord(coinType: CoinType)
    func inFavorites(coinType: CoinType) -> Bool
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

protocol IWalletConnectSessionStorage {
    func sessions(accountId: String, chainIds: [Int]) -> [WalletConnectSession]
    func save(session: WalletConnectSession)
    func deleteSession(peerId: String)
    func deleteSessions(accountId: String)
}

protocol IDeepLinkManager {
    func handle(url: URL) -> Bool
    var newSchemeObservable: Observable<DeepLinkManager.DeepLink?> { get }
}

protocol IAccountSettingRecordStorage {
    func accountSetting(accountId: String, key: String) -> AccountSettingRecord?
    func save(accountSetting: AccountSettingRecord)
    func deleteAllAccountSettings(accountId: String)
}

protocol IEnabledWalletCacheStorage {
    func enabledWalletCaches(accountId: String) -> [EnabledWalletCache]
    func save(enabledWalletCaches: [EnabledWalletCache])
    func deleteEnabledWalletCaches(accountId: String)
}
