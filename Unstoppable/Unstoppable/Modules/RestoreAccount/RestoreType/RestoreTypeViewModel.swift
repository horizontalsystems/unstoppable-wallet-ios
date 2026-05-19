import Combine
import WalletCore

class RestoreTypeViewModel: ObservableObject {
    private let cloudAccountBackupManager = Core.shared.cloudBackupManager
    private let passkeyManager = PasskeyManager()
    private lazy var smartAccountService: CreateSmartAccountService = {
        let core = Core.shared
        return CreateSmartAccountService(
            accountFactory: core.accountFactory,
            accountManager: core.accountManager,
            smartAccountManager: core.smartAccountManager,
            activateDefaultWallets: CreateSmartAccountService.defaultActivator(
                marketKit: core.marketKit,
                walletManager: core.walletManager
            )
        )
    }()

    var isCloudAvailable: Bool {
        cloudAccountBackupManager.isAvailable
    }

    func loginPasskey() async throws -> PasskeyLogin {
        let passkey = try await passkeyManager.login()

        return PasskeyLogin(
            accountName: passkey.name,
            accountType: .mnemonic(words: passkey.mnemonic, salt: "", bip39Compliant: true)
        )
    }

    func restoreSmartAccount() async throws -> Account {
        try await smartAccountService.restore()
    }
}

extension RestoreTypeViewModel {
    struct PasskeyLogin: Hashable {
        let accountName: String
        let accountType: AccountType
    }
}
