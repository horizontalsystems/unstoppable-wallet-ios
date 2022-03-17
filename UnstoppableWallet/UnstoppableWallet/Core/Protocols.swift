import Foundation
import RxSwift
import GRDB
import UniswapKit
import EthereumKit
import ThemeKit
import Alamofire
import HsToolKit
import MarketKit
import BigInt

typealias CoinCode = String

protocol IRandomManager {
    func getRandomIndexes(max: Int, count: Int) -> [Int]
}

protocol ILocalStorage: AnyObject {
    var agreementAccepted: Bool { get set }
    var debugLog: String? { get set }
    var sendInputType: SendInputType? { get set }
    var mainShownOnce: Bool { get set }
    var jailbreakShownOnce: Bool { get set }
    var transactionDataSortMode: TransactionDataSortMode? { get set }
    var lockTimeEnabled: Bool { get set }
    var appLaunchCount: Int { get set }
    var rateAppLastRequestDate: Date? { get set }
    var zcashAlwaysPendingRewind: Bool { get set }

    func defaultProvider(blockchain: EvmBlockchain) -> SwapModule.Dex.Provider
    func setDefaultProvider(blockchain: EvmBlockchain, provider: SwapModule.Dex.Provider)
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
    var explorerTitle: String { get }
    func explorerUrl(transactionHash: String) -> String?
    func transactionsObservable(coin: PlatformCoin?, filter: TransactionTypeFilter) -> Observable<[TransactionRecord]>
    func transactionsSingle(from: TransactionRecord?, coin: PlatformCoin?, filter: TransactionTypeFilter, limit: Int) -> Single<[TransactionRecord]>
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
    var evmKitWrapper: EvmKitWrapper { get }
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

protocol ISystemInfoManager {
    var appVersion: AppVersion { get }
    var passcodeSet: Bool { get }
    var deviceModel: String { get }
    var osVersion: String { get }
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
    func initialSyncSetting(coinType: MarketKit.CoinType) -> InitialSyncSetting?
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

protocol IAddressUriParser {
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
    var currentVersion: AppVersion { get }
}

protocol IRateAppManager {
    func onBalancePageAppear()
    func onBalancePageDisappear()
    func onLaunch()
    func onBecomeActive()
    func onResignActive()
    func forceShow()
}

protocol ITransactionDataSortModeSettingManager {
    var setting: TransactionDataSortMode { get }
    func save(setting: TransactionDataSortMode)
}

protocol IGuidesManager {
    func guideCategoriesSingle(url: URL) -> Single<[GuideCategory]>
}

protocol IFavoriteCoinRecordStorage {
    var favoriteCoinRecords: [FavoriteCoinRecord] { get }
    func save(favoriteCoinRecord: FavoriteCoinRecord)
    func save(favoriteCoinRecords: [FavoriteCoinRecord])
    func deleteFavoriteCoinRecord(coinUid: String)
    func favoriteCoinRecordExists(coinUid: String) -> Bool

    var favoriteCoinRecords_v_0_22: [FavoriteCoinRecord_v_0_22] { get }
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
    func sessions(accountId: String) -> [WalletConnectSession]
    func save(session: WalletConnectSession)
    func deleteSession(peerId: String)
    func deleteSessions(accountId: String)
}

protocol IWalletConnectV2SessionStorage {
    func sessionsV2(accountId: String?) -> [WalletConnectV2Session]
    func save(sessions: [WalletConnectV2Session])
    func deleteSessionV2(topics: [String])
    func deleteSessionsV2(accountId: String)
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

protocol ICustomTokenStorage {
    func customTokens(platformType: PlatformType, filter: String) -> [CustomToken]
    func customTokens(filter: String) -> [CustomToken]
    func customTokens(coinTypeIds: [String]) -> [CustomToken]
    func customToken(coinType: MarketKit.CoinType) -> CustomToken?
    func save(customTokens: [CustomToken])
}

protocol IChartIntervalStorage: AnyObject {
    var interval: HsTimePeriod? { get set }
}

protocol IEvmAccountSyncStateStorage {
    func evmAccountSyncState(accountId: String, chainId: Int) -> EvmAccountSyncState?
    func save(evmAccountSyncState: EvmAccountSyncState)
}

protocol Warning {}
