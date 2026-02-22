import Foundation

class BackupKeychainService: IBackupPasswordStorage {
    private static let service = "unstoppable.money"

    func save(password: String, account: String) async throws {
        guard let data = password.data(using: .utf8) else {
            throw StorageError.encodingFailed
        }

        await delete(account: account)

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Self.service,
            kSecAttrAccount: account,
            kSecAttrSynchronizable: kCFBooleanTrue!,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked,
            kSecValueData: data,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw StorageError.saveFailed(status)
        }
    }

    func load(account: String) async -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Self.service,
            kSecAttrAccount: account,
            kSecAttrSynchronizable: kCFBooleanTrue!,
            kSecReturnData: kCFBooleanTrue!,
            kSecMatchLimit: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let password = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        return password
    }

    @discardableResult
    func delete(account: String) async -> Bool {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Self.service,
            kSecAttrAccount: account,
            kSecAttrSynchronizable: kCFBooleanTrue!,
        ]

        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }

    enum StorageError: LocalizedError {
        case encodingFailed
        case saveFailed(OSStatus)

        var errorDescription: String? {
            switch self {
            case .encodingFailed:
                return "backup.password.keychain.error.encoding".localized
            case let .saveFailed(status):
                return "backup.password.keychain.error.save_failed".localized(status.description)
            }
        }
    }
}
