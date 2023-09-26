import Foundation
import RxSwift
import StorageKit

class AppManager {
    private let accountManager: AccountManager
    private let walletManager: WalletManager
    private let adapterManager: AdapterManager
    private let lockManager: LockManager
    private let keychainKit: IKeychainKit
    private let blurManager: BlurManager
    private let kitCleaner: KitCleaner
    private let debugBackgroundLogger: DebugLogger?
    private let appVersionManager: AppVersionManager
    private let rateAppManager: RateAppManager
    private let logRecordManager: LogRecordManager
    private let deepLinkManager: DeepLinkManager
    private let evmLabelManager: EvmLabelManager
    private let balanceHiddenManager: BalanceHiddenManager
    private let walletConnectSocketConnectionService: WalletConnectSocketConnectionService
    private let nftMetadataSyncer: NftMetadataSyncer

    private let didBecomeActiveSubject = PublishSubject<Void>()
    private let willEnterForegroundSubject = PublishSubject<Void>()

    init(accountManager: AccountManager, walletManager: WalletManager, adapterManager: AdapterManager, lockManager: LockManager,
         keychainKit: IKeychainKit, blurManager: BlurManager,
         kitCleaner: KitCleaner, debugLogger: DebugLogger?,
         appVersionManager: AppVersionManager, rateAppManager: RateAppManager,
         logRecordManager: LogRecordManager,
         deepLinkManager: DeepLinkManager, evmLabelManager: EvmLabelManager, balanceHiddenManager: BalanceHiddenManager,
         walletConnectSocketConnectionService: WalletConnectSocketConnectionService, nftMetadataSyncer: NftMetadataSyncer)
    {
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.lockManager = lockManager
        self.keychainKit = keychainKit
        self.blurManager = blurManager
        self.kitCleaner = kitCleaner
        debugBackgroundLogger = debugLogger
        self.appVersionManager = appVersionManager
        self.rateAppManager = rateAppManager
        self.logRecordManager = logRecordManager
        self.deepLinkManager = deepLinkManager
        self.evmLabelManager = evmLabelManager
        self.balanceHiddenManager = balanceHiddenManager
        self.walletConnectSocketConnectionService = walletConnectSocketConnectionService
        self.nftMetadataSyncer = nftMetadataSyncer
    }
}

extension AppManager {
    func didFinishLaunching() {
        debugBackgroundLogger?.logFinishLaunching()

        keychainKit.handleLaunch()
        accountManager.handleLaunch()
        walletManager.preloadWallets()
        kitCleaner.clear()

        rateAppManager.onLaunch()

        evmLabelManager.sync()
    }

    func willResignActive() {
        blurManager.willResignActive()
        rateAppManager.onResignActive()
    }

    func didBecomeActive() {
        didBecomeActiveSubject.onNext(())

        blurManager.didBecomeActive()
        rateAppManager.onBecomeActive()
        logRecordManager.onBecomeActive()
    }

    func didEnterBackground() {
        debugBackgroundLogger?.logEnterBackground()

        lockManager.didEnterBackground()
        walletConnectSocketConnectionService.didEnterBackground()
        balanceHiddenManager.didEnterBackground()
    }

    func willEnterForeground() {
        accountManager.handleForeground()

        blurManager.willEnterForeground()
        debugBackgroundLogger?.logEnterForeground()
        willEnterForegroundSubject.onNext(())

        keychainKit.handleForeground()
        lockManager.willEnterForeground()
        adapterManager.refresh()
        walletConnectSocketConnectionService.willEnterForeground()

        nftMetadataSyncer.sync()
    }

    func willTerminate() {
        debugBackgroundLogger?.logTerminate()
    }

    func didReceive(url: URL) -> Bool {
        deepLinkManager.handle(url: url)
    }
}

extension AppManager: IAppManager {
    var didBecomeActiveObservable: Observable<Void> {
        didBecomeActiveSubject.asObservable()
    }

    var willEnterForegroundObservable: Observable<Void> {
        willEnterForegroundSubject.asObservable()
    }
}
