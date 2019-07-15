import RxSwift

class AppManager {
    private let accountManager: IAccountManager
    private let adapterManager: IAdapterManager
    private let lockManager: ILockManager
    private let biometryManager: IBiometryManager
    private let blurManager: IBlurManager

    private let resignActiveSubject = PublishSubject<()>()
    private let becomeActiveSubject = PublishSubject<()>()
    private let enterBackgroundSubject = PublishSubject<()>()

    init(accountManager: IAccountManager, adapterManager: IAdapterManager, lockManager: ILockManager, biometryManager: IBiometryManager, blurManager: IBlurManager) {
        self.accountManager = accountManager
        self.adapterManager = adapterManager
        self.lockManager = lockManager
        self.biometryManager = biometryManager
        self.blurManager = blurManager
    }

}

extension AppManager: IAppManager {

    func onStart() {
        accountManager.preloadAccounts()
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
