class PasscodeLockManager {
    private let systemInfoManager: ISystemInfoManager
    private let accountManager: IAccountManager
    private let walletManager: IWalletManager
    private let router: IPasscodeLockRouter

    private(set) var locked: Bool = false

    init(systemInfoManager: ISystemInfoManager, accountManager: IAccountManager, walletManager: IWalletManager, router: IPasscodeLockRouter) {
        self.systemInfoManager = systemInfoManager
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.router = router
    }

    private func lockIfRequired() {
        guard !locked else {
            return
        }

        lock()
        router.showNoPasscode()
    }

    private func unlockIfRequired() {
        guard locked else {
            return
        }

        locked = false
        router.showLaunch()
    }

    private func lock() {
        locked = true

        accountManager.clear()
        walletManager.enable(wallets: [])
    }

}

extension PasscodeLockManager: IPasscodeLockManager {

    func didFinishLaunching() {
        if !systemInfoManager.passcodeSet {
            lock()
        }
    }

    func willEnterForeground() {
        if systemInfoManager.passcodeSet {
            unlockIfRequired()
        } else {
            lockIfRequired()
        }
    }

}
