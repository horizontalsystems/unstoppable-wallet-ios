import UIKit
import StorageKit

class KeychainKitDelegate {
    private let accountManager: IAccountManager
    private let walletManager: WalletManagerNew

    init(accountManager: IAccountManager, walletManager: WalletManagerNew) {
        self.accountManager = accountManager
        self.walletManager = walletManager
    }

    private func show(viewController: UIViewController) {
        UIApplication.shared.windows.first { $0.isKeyWindow }?.set(newRootController: viewController)
    }

}

extension KeychainKitDelegate: IKeychainKitDelegate {

    func onInitialLock() {
        accountManager.clear()
        walletManager.clearWallets()
    }

    public func onLock() {
        show(viewController: NoPasscodeViewController(mode: .noPasscode))
    }

    public func onUnlock() {
        show(viewController: LaunchRouter.module())
    }

}
