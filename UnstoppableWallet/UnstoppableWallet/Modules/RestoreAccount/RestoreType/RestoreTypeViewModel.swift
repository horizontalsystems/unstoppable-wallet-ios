import Combine

class RestoreTypeViewModel: ObservableObject {
    private let cloudAccountBackupManager = Core.shared.cloudBackupManager
    private let passkeyManager = PasskeyManager()

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
}

extension RestoreTypeViewModel {
    struct PasskeyLogin: Hashable {
        let accountName: String
        let accountType: AccountType
    }
}
