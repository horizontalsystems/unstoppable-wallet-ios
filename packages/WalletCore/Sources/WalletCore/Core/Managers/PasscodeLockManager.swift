import HsExtensions
import LocalAuthentication

public class PasscodeLockManager {
    private let accountManager: AccountManager
    private let walletManager: WalletManager

    @DistinctPublished public private(set) var state: PasscodeLockState = .passcodeSet {
        didSet {
            switch state {
            case .passcodeNotSet: onSecureStorageInvalidation()
            default: ()
            }
        }
    }

    public init(accountManager: AccountManager, walletManager: WalletManager) {
        self.accountManager = accountManager
        self.walletManager = walletManager

        state = resolveState()
    }

    private func onSecureStorageInvalidation() {
        accountManager.clear()
        walletManager.clearWallets()
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

public extension PasscodeLockManager {
    func handleForeground() {
        state = resolveState()
    }
}
