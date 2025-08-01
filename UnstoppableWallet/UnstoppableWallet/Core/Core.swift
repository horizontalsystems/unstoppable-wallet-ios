import Foundation
import GRDB
import HsToolKit
import MarketKit

class Core {
    static var instance: Core?

    static func initApp() throws {
        instance = try Core()
    }

    static var shared: Core {
        instance!
    }

    let marketKit: MarketKit.Kit

    let userDefaultsStorage: UserDefaultsStorage
    let localStorage: LocalStorage
    let keychainStorage: KeychainStorage

    let coverManager: CoverManager
    let pasteboardManager: PasteboardManager
    let reachabilityManager: ReachabilityManager
    let appIconManager: AppIconManager
    let biometryManager: BiometryManager
    let passcodeManager: PasscodeManager
    let lockManager: LockManager
    let lockoutManager: LockoutManager
    let keychainManager: KeychainManager
    let themeManager: ThemeManager
    let systemInfoManager: SystemInfoManager
    let testNetManager: TestNetManager
    let deepLinkManager: DeepLinkManager
    let deeplinkStorage: DeeplinkStorage
    let launchScreenManager: LaunchScreenManager
    let appSettingManager: AppSettingManager
    let balanceHiddenManager: BalanceHiddenManager
    let balanceConversionManager: BalanceConversionManager
    let walletButtonHiddenManager: WalletButtonHiddenManager
    let priceChangeModeManager: PriceChangeModeManager

    let appVersionStorage: AppVersionStorage
    let appVersionManager: AppVersionManager

    let logRecordManager: LogRecordManager
    let logger: Logger

    let currencyManager: CurrencyManager
    let networkManager: NetworkManager
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
    let amountRoundingManager: AmountRoundingManager

    let btcBlockchainManager: BtcBlockchainManager
    let evmSyncSourceManager: EvmSyncSourceManager
    let restoreStateManager: RestoreStateManager
    let evmBlockchainManager: EvmBlockchainManager
    let evmLabelManager: EvmLabelManager
    let tronAccountManager: TronAccountManager
    let tonKitManager: TonKitManager
    let stellarKitManager: StellarKitManager

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
    let spamManager: SpamManager

    let purchaseManager: PurchaseManager

    let recentAddressStorage: RecentAddressStorage

    let kitCleaner: KitCleaner
    let appManager: AppManager

    let appEventHandler: EventHandler

    let performanceDataManager: PerformanceDataManager
    let releaseNotesService: ReleaseNotesService

    private let startScreenAlertManager: StartScreenAlertManager
    private let deepLinkViewManager: DeepLinkViewManager

    let valueFormatter: CurrencyValueFormatter

    init() throws {
        let databaseURL = try FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("bank.sqlite")
        let dbPool = try DatabasePool(path: databaseURL.path)

        userDefaultsStorage = UserDefaultsStorage()
        localStorage = LocalStorage(userDefaultsStorage: userDefaultsStorage)
        keychainStorage = KeychainStorage(service: "io.horizontalsystems.bank.dev")
        let sharedLocalStorage = SharedLocalStorage()

        try StorageMigrator.migrate(dbPool: dbPool, localStorage: localStorage)

        marketKit = try MarketKit.Kit.instance(
            hsApiBaseUrl: AppConfig.marketApiUrl,
            hsProviderApiKey: AppConfig.hsProviderApiKey,
            minLogLevel: .error
        )
        marketKit.sync()

        pasteboardManager = PasteboardManager()
        reachabilityManager = ReachabilityManager()
        appIconManager = AppIconManager()
        biometryManager = BiometryManager(userDefaultsStorage: userDefaultsStorage)
        passcodeManager = PasscodeManager(biometryManager: biometryManager, keychainStorage: keychainStorage)
        lockManager = LockManager(passcodeManager: passcodeManager, userDefaultsStorage: userDefaultsStorage)
        lockoutManager = LockoutManager(keychainStorage: keychainStorage)
        coverManager = CoverManager(lockManager: lockManager)
        keychainManager = KeychainManager(storage: keychainStorage, userDefaultsStorage: userDefaultsStorage)
        themeManager = ThemeManager.shared
        systemInfoManager = SystemInfoManager()
        testNetManager = TestNetManager(userDefaultsStorage: userDefaultsStorage)
        deepLinkManager = DeepLinkManager()
        deeplinkStorage = DeeplinkStorage()
        launchScreenManager = LaunchScreenManager(userDefaultsStorage: userDefaultsStorage)
        appSettingManager = AppSettingManager(userDefaultsStorage: userDefaultsStorage)
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

        currencyManager = CurrencyManager(storage: sharedLocalStorage)
        networkManager = NetworkManager(logger: logger)
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
        amountRoundingManager = AmountRoundingManager(storage: localStorage)

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

        let tronKitManager = TronKitManager(testNetManager: testNetManager)
        tronAccountManager = TronAccountManager(accountManager: accountManager, walletManager: walletManager, marketKit: marketKit, tronKitManager: tronKitManager, restoreStateManager: restoreStateManager)

        tonKitManager = TonKitManager(restoreStateManager: restoreStateManager, marketKit: marketKit, walletManager: walletManager)
        stellarKitManager = StellarKitManager(restoreStateManager: restoreStateManager, marketKit: marketKit, walletManager: walletManager)

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

        walletConnectManager = WalletConnectManager(walletConnectSessionManager: walletConnectSessionManager)

        let adapterFactory = AdapterFactory(
            evmBlockchainManager: evmBlockchainManager,
            evmSyncSourceManager: evmSyncSourceManager,
            btcBlockchainManager: btcBlockchainManager,
            tronKitManager: tronKitManager,
            tonKitManager: tonKitManager,
            stellarKitManager: stellarKitManager,
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
            stellarKitManager: stellarKitManager,
            btcBlockchainManager: btcBlockchainManager
        )
        transactionAdapterManager = TransactionAdapterManager(
            adapterManager: adapterManager,
            evmBlockchainManager: evmBlockchainManager,
            adapterFactory: adapterFactory
        )

        let spamAddressStorage = try SpamAddressStorage(dbPool: dbPool)
        spamManager = SpamManager(storage: spamAddressStorage, accountManager: accountManager, transactionAdapterManager: transactionAdapterManager)

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
            appSettingManager: appSettingManager,
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

        purchaseManager = PurchaseManager(localStorage: localStorage)

        recentAddressStorage = try RecentAddressStorage(dbPool: dbPool)

        let statStorage = StatStorage(dbPool: dbPool)
        statManager = StatManager(marketKit: marketKit, storage: statStorage, userDefaultsStorage: userDefaultsStorage)

        let tonConnectStorage = try TonConnectStorage(dbPool: dbPool)
        tonConnectManager = TonConnectManager(storage: tonConnectStorage, accountManager: accountManager)

        kitCleaner = KitCleaner(accountManager: accountManager)

        performanceDataManager = PerformanceDataManager(userDefaultsStorage: userDefaultsStorage)
        releaseNotesService = ReleaseNotesService(appVersionManager: appVersionManager)

        appEventHandler = EventHandler(deepLinkManager: deepLinkManager)

        deepLinkViewManager = DeepLinkViewManager(
            eventHandler: appEventHandler,
            walletConnectManager: walletConnectManager,
            accountManager: accountManager,
            cloudBackupManager: cloudBackupManager
        )

        startScreenAlertManager = StartScreenAlertManager(
            accountManager: accountManager,
            lockManager: lockManager,
            jailbreakService: JailbreakService(localStorage: localStorage),
            releaseNotesService: releaseNotesService,
            deeplinkManager: deepLinkManager,
            deeplinkStorage: deeplinkStorage
        )

        valueFormatter = CurrencyValueFormatter(amountRoundingManager: amountRoundingManager)

        let walletConnectHandler = WalletConnectHandlerModule.handler(
            walletConnectManager: walletConnectSessionManager,
            walletConnectRequestHandler: walletConnectRequestHandler,
            cloudAccountBackupManager: cloudBackupManager,
            accountManager: accountManager,
            lockManager: lockManager
        )
        let widgetCoinHandler = WidgetCoinEventHandler(marketKit: marketKit)
        let sendAddressHandler = AddressEventHandler(marketKit: marketKit)
        let telegramUserHandler = TelegramUserHandler(marketKit: marketKit)
        let tonConnectHandler = TonConnectEventHandler(tonConnectManager: tonConnectManager)

        appEventHandler.append(handler: walletConnectHandler)
        // eventHandler.append(handler: tonConnectHandler)
        appEventHandler.append(handler: widgetCoinHandler)
        appEventHandler.append(handler: sendAddressHandler)
        appEventHandler.append(handler: telegramUserHandler)

        appManager = AppManager(
            accountManager: accountManager,
            walletManager: walletManager,
            adapterManager: adapterManager,
            lockManager: lockManager,
            keychainManager: keychainManager,
            passcodeLockManager: passcodeLockManager,
            kitCleaner: kitCleaner,
            coverManager: coverManager,
            appVersionManager: appVersionManager,
            rateAppManager: rateAppManager,
            logRecordManager: logRecordManager,
            deeplinkStorage: deeplinkStorage,
            evmLabelManager: evmLabelManager,
            balanceHiddenManager: balanceHiddenManager,
            statManager: statManager,
            walletConnectSocketConnectionService: walletConnectSocketConnectionService,
            nftMetadataSyncer: nftMetadataSyncer,
            tonKitManager: tonKitManager,
            stellarKitManager: stellarKitManager
        )
    }

    func newSendEnabled(wallet _: Wallet) -> Bool {
        true
        // switch wallet.token.blockchainType {
        // case .ton: return true
        // default: return localStorage.newSendEnabled
        // }
    }
}
