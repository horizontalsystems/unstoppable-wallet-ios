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
    let storage: IEnabledWalletStorage & IAccountRecordStorage & IPriceAlertRecordStorage & IBlockchainSettingsRecordStorage & ICoinRecordStorage

    let themeManager: ThemeManager
    let systemInfoManager: ISystemInfoManager

    let pasteboardManager: IPasteboardManager
    let reachabilityManager: IReachabilityManager

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

    let feeCoinProvider: IFeeCoinProvider
    let feeRateProviderFactory: FeeRateProviderFactory

    let sortTypeManager: ISortTypeManager

    let adapterManager: IAdapterManager

    let dataProviderManager: IFullTransactionDataProviderManager
    let fullTransactionInfoProviderFactory: IFullTransactionInfoProviderFactory

    private let testModeIndicator: TestModeIndicator
    private let walletRemover: WalletRemover

    let priceAlertManager: IPriceAlertManager
    let backgroundPriceAlertManager: IBackgroundPriceAlertManager
    let notificationManager: INotificationManager
    var debugLogger: IDebugLogger?

    let appStatusManager: IAppStatusManager
    let appVersionManager: IAppVersionManager

    let initialSyncSettingsManager: IInitialSyncSettingsManager
    let derivationSettingsManager: IDerivationSettingsManager
    let ethereumRpcModeSettingsManager: IEthereumRpcModeSettingsManager
    let restoreManager: IRestoreManager

    let transactionDataSortModeSettingManager: ITransactionDataSortModeSettingManager

    let kitCleaner: IKitCleaner

    let keychainKitDelegate: KeychainKitDelegate
    let pinKitDelegate: PinKitDelegate

    let rateAppManager: IRateAppManager
    let guidesManager: IGuidesManager

    let erc20ContractInfoProvider: IErc20ContractInfoProvider

    let appManager: AppManager

    init() {
        let logger = Logger(minLogLevel: .error)
        let networkManager = NetworkManager(logger: logger)

        keychainKit = KeychainKit(service: "io.horizontalsystems.bank.dev") 

        appConfigProvider = AppConfigProvider()

        localStorage = LocalStorage(storage: StorageKit.LocalStorage.default)
        storage = GrdbStorage(appConfigProvider: appConfigProvider)

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

        rateManager = RateManager(walletManager: walletManager, currencyKit: currencyKit, rateCoinMapper: RateCoinMapper(), coinMarketCapApiKey: appConfigProvider.coinMarketCapApiKey)

        feeCoinProvider = FeeCoinProvider(appConfigProvider: appConfigProvider)
        feeRateProviderFactory = FeeRateProviderFactory(appConfigProvider: appConfigProvider)

        sortTypeManager = SortTypeManager(localStorage: localStorage)

        let ethereumKitManager = EthereumKitManager(appConfigProvider: appConfigProvider)
        let eosKitManager = EosKitManager(appConfigProvider: appConfigProvider)
        let binanceKitManager = BinanceKitManager(appConfigProvider: appConfigProvider)

        let adapterFactory = AdapterFactory(appConfigProvider: appConfigProvider, ethereumKitManager: ethereumKitManager, eosKitManager: eosKitManager, binanceKitManager: binanceKitManager)
        adapterManager = AdapterManager(adapterFactory: adapterFactory, ethereumKitManager: ethereumKitManager, eosKitManager: eosKitManager, binanceKitManager: binanceKitManager, walletManager: walletManager)

        let settingsStorage: IBlockchainSettingsStorage = BlockchainSettingsStorage(storage: storage)
        derivationSettingsManager = DerivationSettingsManager(walletManager: walletManager, adapterManager: adapterManager, storage: settingsStorage)
        initialSyncSettingsManager = InitialSyncSettingsManager(walletManager: walletManager, adapterManager: adapterManager, appConfigProvider: appConfigProvider, storage: settingsStorage)
        ethereumRpcModeSettingsManager = EthereumRpcModeSettingsManager(ethereumKitManager: ethereumKitManager, walletManager: walletManager, adapterManager: adapterManager, localStorage: localStorage)
        restoreManager = RestoreManager(walletManager: walletManager, accountCreator: accountCreator, accountManager: accountManager)

        transactionDataSortModeSettingManager = TransactionDataSortModeSettingManager(storage: localStorage)

        adapterFactory.derivationSettingsManager = derivationSettingsManager
        adapterFactory.initialSyncSettingsManager = initialSyncSettingsManager
        ethereumKitManager.ethereumRpcModeSettingsManager = ethereumRpcModeSettingsManager

        pinKit = PinKit.Kit(secureStorage: keychainKit.secureStorage, localStorage: StorageKit.LocalStorage.default)
        let blurManager: IBlurManager = BlurManager(pinKit: pinKit)

        dataProviderManager = FullTransactionDataProviderManager(localStorage: localStorage, appConfigProvider: appConfigProvider)
        fullTransactionInfoProviderFactory = FullTransactionInfoProviderFactory(networkManager: networkManager, dataProviderManager: dataProviderManager)

        testModeIndicator = TestModeIndicator(appConfigProvider: appConfigProvider)
        walletRemover = WalletRemover(accountManager: accountManager, walletManager: walletManager)

        let priceAlertStorage: IPriceAlertStorage = PriceAlertStorage(coinManager: coinManager, storage: storage)
        priceAlertManager = PriceAlertManager(walletManager: walletManager, storage: priceAlertStorage)
        notificationManager = NotificationManager()

        let notificationFactory = NotificationFactory(emojiHelper: EmojiHelper())
        let priceAlertHandler = PriceAlertHandler(priceAlertStorage: priceAlertStorage, notificationManager: notificationManager, notificationFactory: notificationFactory)

        backgroundPriceAlertManager = BackgroundPriceAlertManager(rateManager: rateManager, priceAlertStorage: priceAlertStorage, priceAlertHandler: priceAlertHandler, debugBackgroundLogger: debugLogger)

        appStatusManager = AppStatusManager(systemInfoManager: systemInfoManager, localStorage: localStorage, predefinedAccountTypeManager: predefinedAccountTypeManager, walletManager: walletManager, adapterManager: adapterManager, ethereumKitManager: ethereumKitManager, eosKitManager: eosKitManager, binanceKitManager: binanceKitManager)
        appVersionManager = AppVersionManager(systemInfoManager: systemInfoManager, localStorage: localStorage)

        keychainKitDelegate = KeychainKitDelegate(accountManager: accountManager, walletManager: walletManager)
        keychainKit.set(delegate: keychainKitDelegate)

        pinKitDelegate = PinKitDelegate()
        pinKit.set(delegate: pinKitDelegate)

        rateAppManager = RateAppManager(walletManager: walletManager, adapterManager: adapterManager, localStorage: localStorage)

        guidesManager = GuidesManager(networkManager: networkManager)

        erc20ContractInfoProvider = Erc20ContractInfoProvider(appConfigProvider: appConfigProvider, networkManager: networkManager)

        appManager = AppManager(
                accountManager: accountManager,
                walletManager: walletManager,
                adapterManager: adapterManager,
                pinKit: pinKit,
                keychainKit: keychainKit,
                blurManager: blurManager,
                notificationManager: notificationManager,
                backgroundPriceAlertManager: backgroundPriceAlertManager,
                kitCleaner: kitCleaner,
                debugLogger: debugLogger,
                appVersionManager: appVersionManager,
                rateAppManager: rateAppManager
        )
    }

}
