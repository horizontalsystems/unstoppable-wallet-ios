import Foundation
import GRDB
import HsToolKit
import MarketKit
import ThemeKit

class App {
    static var instance: App?

    static func initApp() throws {
        instance = try App()
    }

    static var shared: App {
        instance!
    }

    let marketKit: MarketKit.Kit

    let userDefaultsStorage: UserDefaultsStorage
    let localStorage: LocalStorage
    let keychainStorage: KeychainStorage

    let pasteboardManager: PasteboardManager
    let reachabilityManager: ReachabilityManager
    let appIconManager: AppIconManager
    let biometryManager: BiometryManager
    let passcodeManager: PasscodeManager
    let lockDelegate: LockDelegate
    let lockManager: LockManager
    let lockoutManager: LockoutManager
    let blurManager: BlurManager
    let keychainManager: KeychainManager
    let themeManager: ThemeManager
    let systemInfoManager: SystemInfoManager
    let testNetManager: TestNetManager
    let deepLinkManager: DeepLinkManager
    let launchScreenManager: LaunchScreenManager
    let balancePrimaryValueManager: BalancePrimaryValueManager
    let balanceHiddenManager: BalanceHiddenManager
    let balanceConversionManager: BalanceConversionManager
    let walletButtonHiddenManager: WalletButtonHiddenManager
    let priceChangeModeManager: PriceChangeModeManager

    let appVersionStorage: AppVersionStorage
    let appVersionManager: AppVersionManager

    let logRecordManager: LogRecordManager
    let logger: Logger
    var debugLogger: DebugLogger?

    let currencyManager: CurrencyManager
    let networkManager: NetworkManager
    let guidesManager: GuidesManager
    let termsManager: TermsManager
    let watchlistManager: WatchlistManager
    let contactManager: ContactBookManager
    let subscriptionManager: SubscriptionManager

    let accountManager: AccountManager
    let accountRestoreWarningManager: AccountRestoreWarningManager
    let accountFactory: AccountFactory
    let backupManager: BackupManager
    let enabledWalletCacheManager: EnabledWalletCacheManager
    let walletManager: WalletManager
    let coinManager: CoinManager
    let passcodeLockManager: PasscodeLockManager
    let cexAssetManager: CexAssetManager

    let btcBlockchainManager: BtcBlockchainManager
    let evmSyncSourceManager: EvmSyncSourceManager
    let restoreStateManager: RestoreStateManager
    let evmBlockchainManager: EvmBlockchainManager
    let evmLabelManager: EvmLabelManager
    let binanceKitManager: BinanceKitManager
    let tronAccountManager: TronAccountManager
    let tonKitManager: TonKitManager

    let restoreSettingsManager: RestoreSettingsManager
    let predefinedBlockchainService: PredefinedBlockchainService

    let feeCoinProvider: FeeCoinProvider
    let feeRateProviderFactory: FeeRateProviderFactory

    let nftMetadataManager: NftMetadataManager
    let nftAdapterManager: NftAdapterManager
    let nftMetadataSyncer: NftMetadataSyncer

    let walletConnectRequestHandler: WalletConnectRequestChain
    let walletConnectManager: WalletConnectManager
    let walletConnectSocketConnectionService: WalletConnectSocketConnectionService
    let walletConnectSessionManager: WalletConnectSessionManager

    let adapterManager: AdapterManager
    let transactionAdapterManager: TransactionAdapterManager
    let rateAppManager: RateAppManager

    let appBackupProvider: AppBackupProvider
    let cloudBackupManager: CloudBackupManager

    let statManager: StatManager

    let tonConnectManager: TonConnectManager

    let kitCleaner: KitCleaner
    let appManager: AppManager

    let appEventHandler = EventHandler()

    init() throws {
        let databaseURL = try FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("bank.sqlite")
        let dbPool = try DatabasePool(path: databaseURL.path)

        try StorageMigrator.migrate(dbPool: dbPool)

        marketKit = try MarketKit.Kit.instance(
            hsApiBaseUrl: AppConfig.marketApiUrl,
            hsProviderApiKey: AppConfig.hsProviderApiKey,
            minLogLevel: .error
        )
        marketKit.sync()

        userDefaultsStorage = UserDefaultsStorage()
        localStorage = LocalStorage(userDefaultsStorage: userDefaultsStorage)
        keychainStorage = KeychainStorage(service: "io.horizontalsystems.bank.dev")
        let sharedLocalStorage = SharedLocalStorage()

        pasteboardManager = PasteboardManager()
        reachabilityManager = ReachabilityManager()
        appIconManager = AppIconManager()
        biometryManager = BiometryManager(userDefaultsStorage: userDefaultsStorage)
        passcodeManager = PasscodeManager(biometryManager: biometryManager, keychainStorage: keychainStorage)
        lockDelegate = LockDelegate()
        lockManager = LockManager(passcodeManager: passcodeManager, userDefaultsStorage: userDefaultsStorage, delegate: lockDelegate)
        lockoutManager = LockoutManager(keychainStorage: keychainStorage)
        blurManager = BlurManager(lockManager: lockManager)
        keychainManager = KeychainManager(storage: keychainStorage, userDefaultsStorage: userDefaultsStorage)
        themeManager = ThemeManager.shared
        systemInfoManager = SystemInfoManager()
        testNetManager = TestNetManager(userDefaultsStorage: userDefaultsStorage)
        deepLinkManager = DeepLinkManager()
        launchScreenManager = LaunchScreenManager(userDefaultsStorage: userDefaultsStorage)
        balancePrimaryValueManager = BalancePrimaryValueManager(userDefaultsStorage: userDefaultsStorage)
        balanceHiddenManager = BalanceHiddenManager(userDefaultsStorage: userDefaultsStorage)
        balanceConversionManager = BalanceConversionManager(marketKit: marketKit, userDefaultsStorage: userDefaultsStorage)
        walletButtonHiddenManager = WalletButtonHiddenManager(userDefaultsStorage: userDefaultsStorage)
        priceChangeModeManager = PriceChangeModeManager(storage: sharedLocalStorage)

        let appVersionRecordStorage = AppVersionRecordStorage(dbPool: dbPool)
        appVersionStorage = AppVersionStorage(storage: appVersionRecordStorage)
        appVersionManager = AppVersionManager(systemInfoManager: systemInfoManager, storage: appVersionStorage)

        let logRecordStorage = LogRecordStorage(dbPool: dbPool)
        logRecordManager = LogRecordManager(storage: logRecordStorage)
        logger = Logger(minLogLevel: .error, storage: logRecordManager)

        if AppConfig.officeMode {
            debugLogger = DebugLogger(localStorage: localStorage, dateProvider: CurrentDateProvider())
        }

        currencyManager = CurrencyManager(storage: sharedLocalStorage)
        networkManager = NetworkManager(logger: logger)
        guidesManager = GuidesManager(networkManager: networkManager)
        termsManager = TermsManager(userDefaultsStorage: userDefaultsStorage)

        watchlistManager = WatchlistManager(storage: sharedLocalStorage, priceChangeModeManager: priceChangeModeManager)

        contactManager = ContactBookManager(localStorage: localStorage, ubiquityContainerIdentifier: AppConfig.privateCloudContainer, helper: ContactBookHelper(), logger: logger)
        subscriptionManager = SubscriptionManager(userDefaultsStorage: userDefaultsStorage, marketKit: marketKit)

        let accountRecordStorage = AccountRecordStorage(dbPool: dbPool)
        let accountStorage = AccountStorage(keychainStorage: keychainStorage, storage: accountRecordStorage)
        let activeAccountStorage = ActiveAccountStorage(dbPool: dbPool)
        accountManager = AccountManager(passcodeManager: passcodeManager, accountStorage: accountStorage, activeAccountStorage: activeAccountStorage)
        accountRestoreWarningManager = AccountRestoreWarningManager(accountManager: accountManager, userDefaultsStorage: userDefaultsStorage)
        accountFactory = AccountFactory(accountManager: accountManager)
        backupManager = BackupManager(accountManager: accountManager)

        let enabledWalletCacheStorage = EnabledWalletCacheStorage(dbPool: dbPool)
        enabledWalletCacheManager = EnabledWalletCacheManager(storage: enabledWalletCacheStorage, accountManager: accountManager)

        let enabledWalletStorage = EnabledWalletStorage(dbPool: dbPool)
        let walletStorage = WalletStorage(marketKit: marketKit, storage: enabledWalletStorage)
        walletManager = WalletManager(accountManager: accountManager, storage: walletStorage)
        coinManager = CoinManager(marketKit: marketKit, walletManager: walletManager)
        passcodeLockManager = PasscodeLockManager(accountManager: accountManager, walletManager: walletManager)

        let cexAssetRecordStorage = CexAssetRecordStorage(dbPool: dbPool)
        cexAssetManager = CexAssetManager(accountManager: accountManager, marketKit: marketKit, storage: cexAssetRecordStorage)

        let blockchainSettingRecordStorage = try BlockchainSettingRecordStorage(dbPool: dbPool)
        let blockchainSettingsStorage = BlockchainSettingsStorage(storage: blockchainSettingRecordStorage)
        btcBlockchainManager = BtcBlockchainManager(marketKit: marketKit, storage: blockchainSettingsStorage)

        let evmSyncSourceStorage = EvmSyncSourceStorage(dbPool: dbPool)
        evmSyncSourceManager = EvmSyncSourceManager(testNetManager: testNetManager, blockchainSettingsStorage: blockchainSettingsStorage, evmSyncSourceStorage: evmSyncSourceStorage)

        let restoreStateStorage = RestoreStateStorage(dbPool: dbPool)
        restoreStateManager = RestoreStateManager(storage: restoreStateStorage)

        let evmAccountManagerFactory = EvmAccountManagerFactory(accountManager: accountManager, walletManager: walletManager, restoreStateManager: restoreStateManager, marketKit: marketKit)
        evmBlockchainManager = EvmBlockchainManager(syncSourceManager: evmSyncSourceManager, testNetManager: testNetManager, marketKit: marketKit, accountManagerFactory: evmAccountManagerFactory)

        let hsLabelProvider = HsLabelProvider(networkManager: networkManager)
        let evmLabelStorage = EvmLabelStorage(dbPool: dbPool)
        let syncerStateStorage = SyncerStateStorage(dbPool: dbPool)
        evmLabelManager = EvmLabelManager(provider: hsLabelProvider, storage: evmLabelStorage, syncerStateStorage: syncerStateStorage)

        binanceKitManager = BinanceKitManager()
        let tronKitManager = TronKitManager(testNetManager: testNetManager)
        tronAccountManager = TronAccountManager(accountManager: accountManager, walletManager: walletManager, marketKit: marketKit, tronKitManager: tronKitManager, restoreStateManager: restoreStateManager)

        tonKitManager = TonKitManager(restoreStateManager: restoreStateManager, marketKit: marketKit, walletManager: walletManager)

        let restoreSettingsStorage = RestoreSettingsStorage(dbPool: dbPool)
        restoreSettingsManager = RestoreSettingsManager(storage: restoreSettingsStorage)
        predefinedBlockchainService = PredefinedBlockchainService(restoreSettingsManager: restoreSettingsManager)

        feeCoinProvider = FeeCoinProvider(marketKit: marketKit)
        feeRateProviderFactory = FeeRateProviderFactory()

        let nftDatabaseStorage = try NftDatabaseStorage(dbPool: dbPool)
        let nftStorage = NftStorage(marketKit: marketKit, storage: nftDatabaseStorage)
        nftMetadataManager = NftMetadataManager(networkManager: networkManager, marketKit: marketKit, storage: nftStorage)
        nftAdapterManager = NftAdapterManager(
            walletManager: walletManager,
            evmBlockchainManager: evmBlockchainManager
        )
        nftMetadataSyncer = NftMetadataSyncer(nftAdapterManager: nftAdapterManager, nftMetadataManager: nftMetadataManager, nftStorage: nftStorage)

        walletConnectRequestHandler = WalletConnectRequestChain.instance(evmBlockchainManager: evmBlockchainManager, accountManager: accountManager)
        walletConnectManager = WalletConnectManager(accountManager: accountManager, evmBlockchainManager: evmBlockchainManager)

        let walletClientInfo = WalletConnectClientInfo(
            projectId: AppConfig.walletConnectV2ProjectKey ?? "c4f79cc821944d9680842e34466bfb",
            relayHost: "relay.walletconnect.com",
            name: AppConfig.appName,
            description: "",
            url: AppConfig.appWebPageLink,
            icons: ["https://raw.githubusercontent.com/horizontalsystems/HS-Design/master/PressKit/UW-AppIcon-on-light.png"]
        )

        walletConnectSocketConnectionService = WalletConnectSocketConnectionService(reachabilityManager: reachabilityManager, logger: logger)
        let walletConnectService = WalletConnectService(
            connectionService: walletConnectSocketConnectionService,
            info: walletClientInfo,
            logger: logger
        )
        let walletConnectSessionStorage = WalletConnectSessionStorage(dbPool: dbPool)
        walletConnectSessionManager = WalletConnectSessionManager(
            service: walletConnectService,
            storage: walletConnectSessionStorage,
            accountManager: accountManager,
            requestHandler: walletConnectRequestHandler,
            currentDateProvider: CurrentDateProvider()
        )

        let adapterFactory = AdapterFactory(
            evmBlockchainManager: evmBlockchainManager,
            evmSyncSourceManager: evmSyncSourceManager,
            binanceKitManager: binanceKitManager,
            btcBlockchainManager: btcBlockchainManager,
            tronKitManager: tronKitManager,
            tonKitManager: tonKitManager,
            restoreSettingsManager: restoreSettingsManager,
            coinManager: coinManager,
            evmLabelManager: evmLabelManager
        )
        adapterManager = AdapterManager(
            adapterFactory: adapterFactory,
            walletManager: walletManager,
            evmBlockchainManager: evmBlockchainManager,
            tronKitManager: tronKitManager,
            tonKitManager: tonKitManager,
            btcBlockchainManager: btcBlockchainManager
        )
        transactionAdapterManager = TransactionAdapterManager(
            adapterManager: adapterManager,
            evmBlockchainManager: evmBlockchainManager,
            adapterFactory: adapterFactory
        )

        rateAppManager = RateAppManager(walletManager: walletManager, adapterManager: adapterManager, localStorage: localStorage)

        let chartRepository = ChartIndicatorsRepository(localStorage: localStorage, subscriptionManager: subscriptionManager)
        appBackupProvider = AppBackupProvider(
            accountManager: accountManager,
            accountFactory: accountFactory,
            walletManager: walletManager,
            watchlistManager: watchlistManager,
            evmSyncSourceManager: evmSyncSourceManager,
            btcBlockchainManager: btcBlockchainManager,
            restoreSettingsManager: restoreSettingsManager,
            chartRepository: chartRepository,
            localStorage: localStorage,
            languageManager: LanguageManager.shared,
            currencyManager: currencyManager,
            themeManager: themeManager,
            launchScreenManager: launchScreenManager,
            appIconManager: appIconManager,
            balancePrimaryValueManager: balancePrimaryValueManager,
            balanceConversionManager: balanceConversionManager,
            balanceHiddenManager: balanceHiddenManager,
            contactManager: contactManager,
            priceChangeModeManager: priceChangeModeManager,
            walletButtonHiddenManager: walletButtonHiddenManager
        )
        cloudBackupManager = CloudBackupManager(
            ubiquityContainerIdentifier: AppConfig.sharedCloudContainer,
            appBackupProvider: appBackupProvider,
            logger: logger
        )

        let statStorage = StatStorage(dbPool: dbPool)
        statManager = StatManager(marketKit: marketKit, storage: statStorage, userDefaultsStorage: userDefaultsStorage)

        let tonConnectStorage = try TonConnectStorage(dbPool: dbPool)
        tonConnectManager = TonConnectManager(storage: tonConnectStorage, accountManager: accountManager)

        kitCleaner = KitCleaner(accountManager: accountManager)

        appManager = AppManager(
            accountManager: accountManager,
            walletManager: walletManager,
            adapterManager: adapterManager,
            lockManager: lockManager,
            keychainManager: keychainManager,
            passcodeLockManager: passcodeLockManager,
            blurManager: blurManager,
            kitCleaner: kitCleaner,
            debugLogger: debugLogger,
            appVersionManager: appVersionManager,
            rateAppManager: rateAppManager,
            logRecordManager: logRecordManager,
            deepLinkManager: deepLinkManager,
            evmLabelManager: evmLabelManager,
            balanceHiddenManager: balanceHiddenManager,
            statManager: statManager,
            walletConnectSocketConnectionService: walletConnectSocketConnectionService,
            nftMetadataSyncer: nftMetadataSyncer,
            tonKitManager: tonKitManager
        )
    }

    func newSendEnabled(wallet: Wallet) -> Bool {
        switch wallet.token.blockchainType {
        case .ton: return true
        default: return localStorage.newSendEnabled
        }
    }
}
