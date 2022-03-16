import UIKit
import StorageKit

class KeychainKitDelegate {
    private let accountManager: AccountManager
    private let walletManager: WalletManager

    init(accountManager: AccountManager, walletManager: WalletManager) {
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
