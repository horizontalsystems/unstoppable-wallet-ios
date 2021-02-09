import ThemeKit
import StorageKit
import PinKit
import CurrencyKit
import HsToolKit

class App {
    static let shared = App()

    let keychainKit: IKeychainKit
    let pinKit: IPinKit

    let appConfigProvider: IAppConfigProvider

    let localStorage: ILocalStorage & IChartTypeStorage
    let storage: IEnabledWalletStorage & IAccountRecordStorage & IPriceAlertRecordStorage & IBlockchainSettingsRecordStorage & ICoinRecordStorage & IPriceAlertRequestRecordStorage & ILogRecordStorage & IFavoriteCoinRecordStorage

    let themeManager: ThemeManager
    let systemInfoManager: ISystemInfoManager

    let pasteboardManager: IPasteboardManager
    let reachabilityManager: IReachabilityManager
    let networkManager: NetworkManager

    let wordsManager: IWordsManager

    let accountManager: IAccountManager
    let backupManager: IBackupManager

    let coinManager: ICoinManager

    let walletFactory: IWalletFactory
    let walletManager: IWalletManager

    let accountCreator: IAccountCreator
    let predefinedAccountTypeManager: IPredefinedAccountTypeManager

    let currencyKit: ICurrencyKit

    let rateManager: IRateManager & IPostsManager
    let favoritesManager: IFavoritesManager

    let feeCoinProvider: IFeeCoinProvider
    let feeRateProviderFactory: FeeRateProviderFactory

    let sortTypeManager: ISortTypeManager

    let adapterManager: IAdapterManager

    private let testModeIndicator: TestModeIndicator
    private let walletRemover: WalletRemover

    var remoteAlertManager: IRemoteAlertManager
    let priceAlertManager: IPriceAlertManager
    let notificationManager: INotificationManager
    let logRecordManager: ILogRecordManager & ILogStorage

    var debugLogger: IDebugLogger?
    let logger: Logger

    let appStatusManager: IAppStatusManager
    let appVersionManager: IAppVersionManager

    let initialSyncSettingsManager: IInitialSyncSettingsManager
    let derivationSettingsManager: IDerivationSettingsManager
    let bitcoinCashCoinTypeManager: BitcoinCashCoinTypeManager
    let ethereumRpcModeSettingsManager: IEthereumRpcModeSettingsManager

    let transactionDataSortModeSettingManager: ITransactionDataSortModeSettingManager

    let kitCleaner: IKitCleaner

    let keychainKitDelegate: KeychainKitDelegate
    let pinKitDelegate: PinKitDelegate

    let rateAppManager: IRateAppManager
    let guidesManager: IGuidesManager
    let termsManager: ITermsManager

    let erc20ContractInfoProvider: IErc20ContractInfoProvider

    let walletConnectSessionStore: WalletConnectSessionStore

    let appManager: AppManager
    let ethereumKitManager: EthereumKitManager

    init() {
        appConfigProvider = AppConfigProvider()

        localStorage = LocalStorage(storage: StorageKit.LocalStorage.default)
        storage = GrdbStorage(appConfigProvider: appConfigProvider)
        logRecordManager = LogRecordManager(storage: storage)

        logger = Logger(minLogLevel: .error, storage: logRecordManager)
        networkManager = NetworkManager(logger: logger)

        keychainKit = KeychainKit(service: "io.horizontalsystems.bank.dev")

        themeManager = ThemeManager.shared
        systemInfoManager = SystemInfoManager()

        if appConfigProvider.officeMode {
            debugLogger = DebugLogger(localStorage: localStorage, dateProvider: CurrentDateProvider())
        }

        pasteboardManager = PasteboardManager()
        reachabilityManager = ReachabilityManager()

        wordsManager = WordsManager()

        let accountStorage: IAccountStorage = AccountStorage(secureStorage: keychainKit.secureStorage, storage: storage)
        accountManager = AccountManager(storage: accountStorage)
        backupManager = BackupManager(accountManager: accountManager)

        kitCleaner = KitCleaner(accountManager: accountManager)

        let coinStorage: ICoinStorage = CoinStorage(storage: storage)
        coinManager = CoinManager(appConfigProvider: appConfigProvider, storage: coinStorage)

        walletFactory = WalletFactory()
        let walletStorage: IWalletStorage = WalletStorage(coinManager: coinManager, walletFactory: walletFactory, storage: storage)
        walletManager = WalletManager(accountManager: accountManager, walletFactory: walletFactory, storage: walletStorage, kitCleaner: kitCleaner)

        accountCreator = AccountCreator(accountFactory: AccountFactory(), wordsManager: wordsManager)
        predefinedAccountTypeManager = PredefinedAccountTypeManager(appConfigProvider: appConfigProvider, accountManager: accountManager)

        currencyKit = CurrencyKit.Kit(localStorage: StorageKit.LocalStorage.default, currencyCodes: appConfigProvider.currencyCodes)

        feeCoinProvider = FeeCoinProvider(appConfigProvider: appConfigProvider)
        feeRateProviderFactory = FeeRateProviderFactory(appConfigProvider: appConfigProvider)

        rateManager = RateManager(walletManager: walletManager, currencyKit: currencyKit, rateCoinMapper: RateCoinMapper(), feeCoinProvider: feeCoinProvider, coinMarketCapApiKey: appConfigProvider.coinMarketCapApiKey, cryptoCompareApiKey: appConfigProvider.cryptoCompareApiKey, uniswapSubgraphUrl: appConfigProvider.uniswapSubgraphUrl)
        favoritesManager = FavoritesManager(storage: storage)

        sortTypeManager = SortTypeManager(localStorage: localStorage)

        ethereumKitManager = EthereumKitManager(appConfigProvider: appConfigProvider)
        let binanceKitManager = BinanceKitManager(appConfigProvider: appConfigProvider)

        let adapterFactory = AdapterFactory(appConfigProvider: appConfigProvider, ethereumKitManager: ethereumKitManager, binanceKitManager: binanceKitManager)
        adapterManager = AdapterManager(adapterFactory: adapterFactory, ethereumKitManager: ethereumKitManager, binanceKitManager: binanceKitManager, walletManager: walletManager)

        let settingsStorage: IBlockchainSettingsStorage = BlockchainSettingsStorage(storage: storage)
        derivationSettingsManager = DerivationSettingsManager(walletManager: walletManager, adapterManager: adapterManager, storage: settingsStorage)
        initialSyncSettingsManager = InitialSyncSettingsManager(walletManager: walletManager, adapterManager: adapterManager, appConfigProvider: appConfigProvider, storage: settingsStorage)
        bitcoinCashCoinTypeManager = BitcoinCashCoinTypeManager(walletManager: walletManager, adapterManager: adapterManager, storage: settingsStorage)
        ethereumRpcModeSettingsManager = EthereumRpcModeSettingsManager(ethereumKitManager: ethereumKitManager, walletManager: walletManager, adapterManager: adapterManager, localStorage: localStorage)

        transactionDataSortModeSettingManager = TransactionDataSortModeSettingManager(storage: localStorage)

        adapterFactory.derivationSettingsManager = derivationSettingsManager
        adapterFactory.initialSyncSettingsManager = initialSyncSettingsManager
        adapterFactory.bitcoinCashCoinTypeManager = bitcoinCashCoinTypeManager
        ethereumKitManager.ethereumRpcModeSettingsManager = ethereumRpcModeSettingsManager

        pinKit = PinKit.Kit(secureStorage: keychainKit.secureStorage, localStorage: StorageKit.LocalStorage.default)
        let blurManager: IBlurManager = BlurManager(pinKit: pinKit)

        testModeIndicator = TestModeIndicator(appConfigProvider: appConfigProvider)
        walletRemover = WalletRemover(accountManager: accountManager, walletManager: walletManager)

        let priceAlertRequestStorage: IPriceAlertRequestStorage = PriceAlertRequestStorage(storage: storage)
        remoteAlertManager = RemoteAlertManager(networkManager: networkManager, reachabilityManager: reachabilityManager, appConfigProvider: appConfigProvider, storage: priceAlertRequestStorage)

        let priceAlertStorage: IPriceAlertStorage = PriceAlertStorage(coinManager: coinManager, storage: storage)
        priceAlertManager = PriceAlertManager(walletManager: walletManager, remoteAlertManager: remoteAlertManager, storage: priceAlertStorage, localStorage: localStorage)

        notificationManager = NotificationManager(priceAlertManager: priceAlertManager, remoteAlertManager: remoteAlertManager, storage: localStorage)

        remoteAlertManager.notificationManager = notificationManager

        appStatusManager = AppStatusManager(systemInfoManager: systemInfoManager, localStorage: localStorage, predefinedAccountTypeManager: predefinedAccountTypeManager, walletManager: walletManager, adapterManager: adapterManager, ethereumKitManager: ethereumKitManager, binanceKitManager: binanceKitManager, logRecordManager: logRecordManager)
        appVersionManager = AppVersionManager(systemInfoManager: systemInfoManager, localStorage: localStorage)

        keychainKitDelegate = KeychainKitDelegate(accountManager: accountManager, walletManager: walletManager)
        keychainKit.set(delegate: keychainKitDelegate)

        pinKitDelegate = PinKitDelegate()
        pinKit.set(delegate: pinKitDelegate)

        rateAppManager = RateAppManager(walletManager: walletManager, adapterManager: adapterManager, localStorage: localStorage)

        guidesManager = GuidesManager(networkManager: networkManager)
        termsManager = TermsManager(storage: StorageKit.LocalStorage.default)

        erc20ContractInfoProvider = Erc20ContractInfoProvider(appConfigProvider: appConfigProvider, networkManager: networkManager)

        walletConnectSessionStore = WalletConnectSessionStore(accountManager: accountManager, predefinedAccountTypeManager: predefinedAccountTypeManager)

        appManager = AppManager(
                accountManager: accountManager,
                walletManager: walletManager,
                adapterManager: adapterManager,
                pinKit: pinKit,
                keychainKit: keychainKit,
                blurManager: blurManager,
                notificationManager: notificationManager,
                kitCleaner: kitCleaner,
                debugLogger: debugLogger,
                appVersionManager: appVersionManager,
                rateAppManager: rateAppManager,
                remoteAlertManager: remoteAlertManager,
                logRecordManager: logRecordManager
        )
    }

}
