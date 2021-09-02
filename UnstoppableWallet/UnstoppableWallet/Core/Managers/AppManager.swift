import RxSwift
import StorageKit
import PinKit

class AppManager {
    private let accountManager: IAccountManager
    private let walletManager: WalletManager
    private let walletManagerNew: WalletManagerNew
    private let adapterManager: AdapterManager
    private let pinKit: IPinKit
    private let keychainKit: IKeychainKit
    private let blurManager: IBlurManager
    private let notificationManager: INotificationManager
    private let kitCleaner: IKitCleaner
    private let debugBackgroundLogger: IDebugLogger?
    private let appVersionManager: IAppVersionManager
    private let rateAppManager: IRateAppManager
    private let remoteAlertManager: IRemoteAlertManager
    private let logRecordManager: ILogRecordManager
    private let deepLinkManager: IDeepLinkManager

    private let didBecomeActiveSubject = PublishSubject<()>()
    private let willEnterForegroundSubject = PublishSubject<()>()

    init(accountManager: IAccountManager, walletManager: WalletManager, walletManagerNew: WalletManagerNew, adapterManager: AdapterManager, pinKit: IPinKit,
         keychainKit: IKeychainKit, blurManager: IBlurManager, notificationManager: INotificationManager,
         kitCleaner: IKitCleaner, debugLogger: IDebugLogger?,
         appVersionManager: IAppVersionManager, rateAppManager: IRateAppManager,
         remoteAlertManager: IRemoteAlertManager, logRecordManager: ILogRecordManager,
         deepLinkManager: IDeepLinkManager
    ) {
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.walletManagerNew = walletManagerNew
        self.adapterManager = adapterManager
        self.pinKit = pinKit
        self.keychainKit = keychainKit
        self.blurManager = blurManager
        self.notificationManager = notificationManager
        self.kitCleaner = kitCleaner
        self.debugBackgroundLogger = debugLogger
        self.appVersionManager = appVersionManager
        self.rateAppManager = rateAppManager
        self.remoteAlertManager = remoteAlertManager
        self.logRecordManager = logRecordManager
        self.deepLinkManager = deepLinkManager
    }

}

extension AppManager {

    func didFinishLaunching() {
        debugBackgroundLogger?.logFinishLaunching()

        keychainKit.handleLaunch()
        accountManager.handleLaunch()
        walletManager.preloadWallets()
        walletManagerNew.preloadWallets()
        pinKit.didFinishLaunching()
        notificationManager.removeNotifications()
        kitCleaner.clear()
        notificationManager.handleLaunch()

        appVersionManager.checkLatestVersion()
        rateAppManager.onLaunch()

        remoteAlertManager.checkScheduledRequests()
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

        debugBackgroundLogger?.logEnterForeground()
        willEnterForegroundSubject.onNext(())

        keychainKit.handleForeground()
        pinKit.willEnterForeground()
        notificationManager.removeNotifications()
        adapterManager.refresh()
    }

    func willTerminate() {
        debugBackgroundLogger?.logTerminate()
    }

    func didReceivePushToken(tokenData: Data) {
        notificationManager.didReceivePushToken(tokenData: tokenData)
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
