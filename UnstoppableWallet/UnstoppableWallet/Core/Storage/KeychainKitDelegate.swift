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

    func onSecureStorageInvalidation() {
        accountManager.clear()
        walletManager.clearWallets()
    }

    func onPasscodeSet() {
        show(viewController: LaunchModule.viewController())
    }

    func onPasscodeNotSet() {
        show(viewController: NoPasscodeViewController(mode: .noPasscode))
    }

    func onCannotCheckPasscode() {
        show(viewController: NoPasscodeViewController(mode: .cannotCheckPasscode))
    }

}
