import RxSwift

class AppManager {
    private let accountManager: IAccountManager
    private let walletManager: IWalletManager
    private let adapterManager: IAdapterManager
    private let lockManager: ILockManager
    private let biometryManager: IBiometryManager
    private let blurManager: IBlurManager
    private let localStorage: ILocalStorage
    private let secureStorage: ISecureStorage

    private let resignActiveSubject = PublishSubject<()>()
    private let becomeActiveSubject = PublishSubject<()>()
    private let enterBackgroundSubject = PublishSubject<()>()

    init(accountManager: IAccountManager, walletManager: IWalletManager, adapterManager: IAdapterManager, lockManager: ILockManager, biometryManager: IBiometryManager, blurManager: IBlurManager, localStorage: ILocalStorage, secureStorage: ISecureStorage) {
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.lockManager = lockManager
        self.biometryManager = biometryManager
        self.blurManager = blurManager
        self.localStorage = localStorage
        self.secureStorage = secureStorage
    }

    private func handleFirstLaunch() {
        if !localStorage.didLaunchOnce {
            try? secureStorage.clear()
            localStorage.didLaunchOnce = true
        }
    }

}

extension AppManager: IAppManager {

    func onStart() {
        handleFirstLaunch()

        accountManager.preloadAccounts()
        walletManager.preloadWallets()
        adapterManager.preloadAdapters()
        biometryManager.refresh()
    }

    func onResignActive() {
        resignActiveSubject.onNext(())
        blurManager.willResignActive()
    }

    func onBecomeActive() {
        becomeActiveSubject.onNext(())
        blurManager.didBecomeActive()
    }

    func onEnterBackground() {
        enterBackgroundSubject.onNext(())
        lockManager.didEnterBackground()
    }

    func onEnterForeground() {
        lockManager.willEnterForeground()
        adapterManager.refresh()
        biometryManager.refresh()
    }

    var resignActiveObservable: Observable<()> {
        return resignActiveSubject.asObservable()
    }

    var becomeActiveObservable: Observable<()> {
        return becomeActiveSubject.asObservable()
    }

    var enterBackgroundObservable: Observable<()> {
        return enterBackgroundSubject.asObservable()
    }

}
