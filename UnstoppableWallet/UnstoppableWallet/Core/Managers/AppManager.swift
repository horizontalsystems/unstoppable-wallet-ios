import RxSwift
import StorageKit
import PinKit

class AppManager {
    private let accountManager: IAccountManager
    private let walletManager: WalletManager
    private let adapterManager: AdapterManager
    private let pinKit: IPinKit
    private let keychainKit: IKeychainKit
    private let blurManager: BlurManager
    private let kitCleaner: IKitCleaner
    private let debugBackgroundLogger: IDebugLogger?
    private let appVersionManager: IAppVersionManager
    private let rateAppManager: IRateAppManager
    private let logRecordManager: ILogRecordManager
    private let deepLinkManager: IDeepLinkManager
    private let restoreCustomTokenWorker: RestoreCustomTokenWorker
    private let restoreFavoriteCoinWorker: RestoreFavoriteCoinWorker

    private let didBecomeActiveSubject = PublishSubject<()>()
    private let willEnterForegroundSubject = PublishSubject<()>()

    init(accountManager: IAccountManager, walletManager: WalletManager, adapterManager: AdapterManager, pinKit: IPinKit,
         keychainKit: IKeychainKit, blurManager: BlurManager,
         kitCleaner: IKitCleaner, debugLogger: IDebugLogger?,
         appVersionManager: IAppVersionManager, rateAppManager: IRateAppManager,
         logRecordManager: ILogRecordManager,
         deepLinkManager: IDeepLinkManager, restoreCustomTokenWorker: RestoreCustomTokenWorker, restoreFavoriteCoinWorker: RestoreFavoriteCoinWorker
    ) {
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.pinKit = pinKit
        self.keychainKit = keychainKit
        self.blurManager = blurManager
        self.kitCleaner = kitCleaner
        self.debugBackgroundLogger = debugLogger
        self.appVersionManager = appVersionManager
        self.rateAppManager = rateAppManager
        self.logRecordManager = logRecordManager
        self.deepLinkManager = deepLinkManager
        self.restoreCustomTokenWorker = restoreCustomTokenWorker
        self.restoreFavoriteCoinWorker = restoreFavoriteCoinWorker
    }

}

extension AppManager {

    func didFinishLaunching() {
        debugBackgroundLogger?.logFinishLaunching()

        keychainKit.handleLaunch()
        accountManager.handleLaunch()
        walletManager.preloadWallets()
        pinKit.didFinishLaunching()
        kitCleaner.clear()

        appVersionManager.checkLatestVersion()
        rateAppManager.onLaunch()

        try? restoreCustomTokenWorker.run()
        try? restoreFavoriteCoinWorker.run()
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

        pinKit.didEnterBackground()
    }

    func willEnterForeground() {
        accountManager.handleForeground()

        blurManager.willEnterForeground()
        debugBackgroundLogger?.logEnterForeground()
        willEnterForegroundSubject.onNext(())

        keychainKit.handleForeground()
        pinKit.willEnterForeground()
        adapterManager.refresh()
    }

    func willTerminate() {
        debugBackgroundLogger?.logTerminate()
    }

    func didReceive(url: URL) -> Bool {
        deepLinkManager.handle(url: url)
    }

}

extension AppManager: IAppManager {

    var didBecomeActiveObservable: Observable<()> {
        didBecomeActiveSubject.asObservable()
    }

    var willEnterForegroundObservable: Observable<()> {
        willEnterForegroundSubject.asObservable()
    }

}
