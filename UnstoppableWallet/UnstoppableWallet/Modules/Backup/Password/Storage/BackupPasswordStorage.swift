import Combine

protocol IBackupPasswordStorage {
    func save(password: String, account: String) async throws
    func load(account: String) async -> String?
    func delete(account: String) async -> Bool
}

enum BackupPasswordStorageType {
    case keychain
    case webCredentials
}

enum BackupPasswordStorageFactory {
    // Switch to sharedWebCredentials() when:
    // 1. Web engineer adds webcredentials to apple-app-site-association on unstoppable.money
    // 2. Associated Domains entitlement webcredentials:unstoppable.money added in Xcode
    static func create(type: BackupPasswordStorageType) -> IBackupPasswordStorage {
        switch type {
        case .keychain: return BackupKeychainService()
        case .webCredentials: return BackupSharedWebCredentialsService()
        }
    }
}
