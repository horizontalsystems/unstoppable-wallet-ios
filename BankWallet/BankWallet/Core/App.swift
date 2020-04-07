import ThemeKit
import StorageKit
import PinKit
import CurrencyKit

class App {
    static let shared = App()

    let keychainKit: IKeychainKit
    let pinKit: IPinKit

    let appConfigProvider: IAppConfigProvider

    let localStorage: ILocalStorage & IChartTypeStorage
    let storage: IEnabledWalletStorage & IAccountRecordStorage & IPriceAlertRecordStorage & IBlockchainSettingsRecordStorage

    let themeManager: ThemeManager
    let systemInfoManager: ISystemInfoManager

    let pasteboardManager: IPasteboardManager
    let reachabilityManager: IReachabilityManager

    let wordsManager: IWordsManager

    let accountManager: IAccountManager
    let backupManager: IBackupManager

    let walletFactory: IWalletFactory
    let walletManager: IWalletManager

    let accountCreator: IAccountCreator
    let predefinedAccountTypeManager: IPredefinedAccountTypeManager

    let currencyKit: ICurrencyKit

    let rateManager: IRateManager & IPostsManager

    let feeCoinProvider: IFeeCoinProvider
    let feeRateProviderFactory: FeeRateProviderFactory

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
    let restoreManager: IRestoreManager

    let rateCoinMapper: RateCoinMapper

    let kitCleaner: IKitCleaner

    let keychainKitDelegate: KeychainKitDelegate
    let pinKitDelegate: PinKitDelegate

    let rateAppManager: IRateAppManager

    let appManager: AppManager

    init() {
        let networkManager = NetworkManager()

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
        reachabilityManager = ReachabilityManager(appConfigProvider: appConfigProvider)

        wordsManager = WordsManager()

        let accountStorage: IAccountStorage = AccountStorage(secureStorage: keychainKit.secureStorage, storage: storage)
        accountManager = AccountManager(storage: accountStorage)
        backupManager = BackupManager(accountManager: accountManager)

        kitCleaner = KitCleaner(accountManager: accountManager)

        walletFactory = WalletFactory()
        let walletStorage: IWalletStorage = WalletStorage(appConfigProvider: appConfigProvider, walletFactory: walletFactory, storage: storage)
        walletManager = WalletManager(accountManager: accountManager, walletFactory: walletFactory, storage: walletStorage, kitCleaner: kitCleaner)

        accountCreator = AccountCreator(accountFactory: AccountFactory(), wordsManager: wordsManager)
        predefinedAccountTypeManager = PredefinedAccountTypeManager(appConfigProvider: appConfigProvider, accountManager: accountManager)

        currencyKit = CurrencyKit.Kit(localStorage: StorageKit.LocalStorage.default, currencyCodes: appConfigProvider.currencyCodes)

        rateCoinMapper = RateCoinMapper()
        rateManager = RateManager(walletManager: walletManager, currencyKit: currencyKit, rateCoinMapper: rateCoinMapper)

        feeCoinProvider = FeeCoinProvider(appConfigProvider: appConfigProvider)
        feeRateProviderFactory = FeeRateProviderFactory(appConfigProvider: appConfigProvider)

        let ethereumKitManager = EthereumKitManager(appConfigProvider: appConfigProvider)
        let eosKitManager = EosKitManager(appConfigProvider: appConfigProvider)
        let binanceKitManager = BinanceKitManager(appConfigProvider: appConfigProvider)

        let settingsStorage: IBlockchainSettingsStorage = BlockchainSettingsStorage(storage: storage)
        initialSyncSettingsManager = InitialSyncSettingsManager(storage: settingsStorage)
        derivationSettingsManager = DerivationSettingsManager(storage: settingsStorage)
        restoreManager = RestoreManager(walletManager: walletManager, derivationSettingsManager: derivationSettingsManager, accountCreator: accountCreator, accountManager: accountManager)

        let adapterFactory: IAdapterFactory = AdapterFactory(appConfigProvider: appConfigProvider, ethereumKitManager: ethereumKitManager, eosKitManager: eosKitManager, binanceKitManager: binanceKitManager, initialSyncSettingsManager: initialSyncSettingsManager, derivationSettingsManager: derivationSettingsManager)
        adapterManager = AdapterManager(adapterFactory: adapterFactory, ethereumKitManager: ethereumKitManager, eosKitManager: eosKitManager, binanceKitManager: binanceKitManager, walletManager: walletManager)

        pinKit = PinKit.Kit(secureStorage: keychainKit.secureStorage, localStorage: StorageKit.LocalStorage.default)
        let blurManager: IBlurManager = BlurManager(pinKit: pinKit)

        dataProviderManager = FullTransactionDataProviderManager(localStorage: localStorage, appConfigProvider: appConfigProvider)

        let jsonApiProvider: IJsonApiProvider = JsonApiProvider(networkManager: networkManager)
        fullTransactionInfoProviderFactory = FullTransactionInfoProviderFactory(apiProvider: jsonApiProvider, dataProviderManager: dataProviderManager)

        testModeIndicator = TestModeIndicator(appConfigProvider: appConfigProvider)
        walletRemover = WalletRemover(accountManager: accountManager, walletManager: walletManager)

        let priceAlertStorage: IPriceAlertStorage = PriceAlertStorage(appConfigProvider: appConfigProvider, storage: storage)
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
