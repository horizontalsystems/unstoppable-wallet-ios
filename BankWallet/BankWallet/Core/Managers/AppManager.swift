import RxSwift

class AppManager {
    private let accountManager: IAccountManager
    private let walletManager: IWalletManager
    private let adapterManager: IAdapterManager
    private let lockManager: ILockManager
    private let passcodeLockManager: IPasscodeLockManager
    private let biometryManager: IBiometryManager
    private let blurManager: IBlurManager
    private let notificationManager: INotificationManager
    private let backgroundPriceAlertManager: IBackgroundPriceAlertManager
    private let localStorage: ILocalStorage
    private let secureStorage: ISecureStorage
    private let kitCleaner: IKitCleaner
    private let debugBackgroundLogger: IDebugBackgroundLogger?

    private let didBecomeActiveSubject = PublishSubject<()>()
    private let willEnterForegroundSubject = PublishSubject<()>()

    init(accountManager: IAccountManager, walletManager: IWalletManager, adapterManager: IAdapterManager, lockManager: ILockManager,
         passcodeLockManager: IPasscodeLockManager, biometryManager: IBiometryManager, blurManager: IBlurManager,
         notificationManager: INotificationManager, backgroundPriceAlertManager: IBackgroundPriceAlertManager,
         localStorage: ILocalStorage, secureStorage: ISecureStorage, kitCleaner: IKitCleaner, debugBackgroundLogger: IDebugBackgroundLogger?) {
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.lockManager = lockManager
        self.passcodeLockManager = passcodeLockManager
        self.biometryManager = biometryManager
        self.blurManager = blurManager
        self.notificationManager = notificationManager
        self.backgroundPriceAlertManager = backgroundPriceAlertManager
        self.localStorage = localStorage
        self.secureStorage = secureStorage
        self.kitCleaner = kitCleaner
        self.debugBackgroundLogger = debugBackgroundLogger
    }

    private func handleFirstLaunch() {
        if !localStorage.didLaunchOnce {
            try? secureStorage.clear()
            localStorage.didLaunchOnce = true
        }
    }

}

extension AppManager {

    func didFinishLaunching() {
        debugBackgroundLogger?.logFinishLaunching()
        handleFirstLaunch()

        passcodeLockManager.didFinishLaunching()
        accountManager.preloadAccounts()
        walletManager.preloadWallets()
        biometryManager.refresh()
        notificationManager.removeNotifications()
        kitCleaner.clear()
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

        passcodeLockManager.willEnterForeground()
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
        return didBecomeActiveSubject.asObservable()
    }

    var willEnterForegroundObservable: Observable<()> {
        return willEnterForegroundSubject.asObservable()
    }

}
