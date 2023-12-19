import LocalAuthentication
import UIKit

class PasscodeLockManager {
    private let accountManager: AccountManager
    private let walletManager: WalletManager

    private(set) var state: PasscodeLockState = .passcodeSet

    init(accountManager: AccountManager, walletManager: WalletManager) {
        self.accountManager = accountManager
        self.walletManager = walletManager
    }

    private func onSecureStorageInvalidation() {
        accountManager.clear()
        walletManager.clearWallets()
    }

    private func onPasscodeSet() {
        show(viewController: LaunchModule.viewController())
    }

    private func onPasscodeNotSet() {
        show(viewController: NoPasscodeViewController(mode: .noPasscode))
    }

    private func onCannotCheckPasscode() {
        show(viewController: NoPasscodeViewController(mode: .cannotCheckPasscode))
    }

    private func show(viewController: UIViewController) {
        UIWindow.keyWindow?.set(newRootController: viewController)
    }
}

extension PasscodeLockManager {
    func handleLaunch() {
        state = resolveState()

        switch state {
        case .passcodeNotSet: onSecureStorageInvalidation()
        default: ()
        }
    }

    func handleForeground() {
        let oldState = state

        state = resolveState()

        guard state != oldState else {
            return
        }

        switch state {
        case .passcodeSet:
            onPasscodeSet()
        case .passcodeNotSet:
            onPasscodeNotSet()
            onSecureStorageInvalidation()
        case .unknown:
            onCannotCheckPasscode()
        }
    }

    private func resolveState() -> PasscodeLockState {
        var error: NSError?

        if LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            return .passcodeSet
        }

        if let error = error as? LAError {
            switch error.code {
            case LAError.passcodeNotSet: return .passcodeNotSet
            default: ()
            }
        }

        return .unknown
    }
}
