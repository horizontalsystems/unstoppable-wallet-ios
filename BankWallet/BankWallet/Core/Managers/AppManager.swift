import RxSwift
import StorageKit

class AppManager {
    private let accountManager: IAccountManager
    private let walletManager: IWalletManager
    private let adapterManager: IAdapterManager
    private let lockManager: ILockManager
    private let keychainKit: IKeychainKit
    private let biometryManager: IBiometryManager
    private let blurManager: IBlurManager
    private let notificationManager: INotificationManager
    private let backgroundPriceAlertManager: IBackgroundPriceAlertManager
    private let kitCleaner: IKitCleaner
    private let debugBackgroundLogger: IDebugLogger?
    private let appVersionManager: IAppVersionManager

    private let didBecomeActiveSubject = PublishSubject<()>()
    private let willEnterForegroundSubject = PublishSubject<()>()

    init(accountManager: IAccountManager, walletManager: IWalletManager, adapterManager: IAdapterManager, lockManager: ILockManager,
         keychainKit: IKeychainKit, biometryManager: IBiometryManager, blurManager: IBlurManager,
         notificationManager: INotificationManager, backgroundPriceAlertManager: IBackgroundPriceAlertManager,
         kitCleaner: IKitCleaner, debugLogger: IDebugLogger?,
         appVersionManager: IAppVersionManager
    ) {
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.lockManager = lockManager
        self.keychainKit = keychainKit
        self.biometryManager = biometryManager
        self.blurManager = blurManager
        self.notificationManager = notificationManager
        self.backgroundPriceAlertManager = backgroundPriceAlertManager
        self.kitCleaner = kitCleaner
        self.debugBackgroundLogger = debugLogger
        self.appVersionManager = appVersionManager
    }

}

extension AppManager {

    func didFinishLaunching() {
        debugBackgroundLogger?.logFinishLaunching()

        keychainKit.handleLaunch()
        accountManager.preloadAccounts()
        walletManager.preloadWallets()
        biometryManager.refresh()
        notificationManager.removeNotifications()
        kitCleaner.clear()

        appVersionManager.checkLatestVersion()
    }

    func willResignActive() {
        blurManager.willResignActive()
    }

    func didBecomeActive() {
        didBecomeActiveSubject.onNext(())

        blurManager.didBecomeActive()
    }

    func didEnterBackground() {
        debugBackgroundLogger?.logEnterBackground()

        lockManager.didEnterBackground()
//        backgroundPriceAlertManager.didEnterBackground()
    }

    func willEnterForeground() {
        debugBackgroundLogger?.logEnterForeground()
        willEnterForegroundSubject.onNext(())

        keychainKit.handleForeground()
        lockManager.willEnterForeground()
        notificationManager.removeNotifications()
        adapterManager.refresh()
        biometryManager.refresh()
    }

    func willTerminate() {
        debugBackgroundLogger?.logTerminate()
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
