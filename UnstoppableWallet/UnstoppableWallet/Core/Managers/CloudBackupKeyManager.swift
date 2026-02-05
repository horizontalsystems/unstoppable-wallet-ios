import Foundation
import HsToolKit
import KeychainAccess
import LocalAuthentication

class CloudBackupKeyManager {
    private static let keychainService = "io.horizontalsystems.unstoppable.cloud-backup"
    private static let passphraseKey = "cloud_backup_passphrase"

    private let keychain: Keychain
    private let biometryManager: BiometryManager
    private let logger: Logger?

    init(biometryManager: BiometryManager, logger: Logger?) {
        self.biometryManager = biometryManager
        self.logger = logger

        keychain = Keychain(service: Self.keychainService)
            .synchronizable(true)
            .accessibility(.afterFirstUnlock)
    }

    var isAvailable: Bool {
        guard biometryManager.biometryType != nil, biometryManager.biometryType != .none else {
            return false
        }
        return FileManager.default.ubiquityIdentityToken != nil
    }

    private func getOrCreatePassphrase() throws -> String {
        if let existing = try storedPassphrase() {
            return existing
        }
        return try generateAndStorePassphrase()
    }

    private func authenticate() async throws {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            logger?.log(level: .debug, message: "CloudBackupKeyManager: biometry not available, error: \(String(describing: error))")
            throw KeyError.biometryNotAvailable
        }

        let success = try await context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "backup.cloud.biometry.reason".localized
        )

        guard success else {
            throw KeyError.authenticationFailed
        }
    }

    private func storedPassphrase() throws -> String? {
        do {
            return try keychain.getString(Self.passphraseKey)
        } catch {
            logger?.log(level: .error, message: "CloudBackupKeyManager: failed to read passphrase: \(error)")
            throw error
        }
    }

    private func generateAndStorePassphrase() throws -> String {
        var randomBytes = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        guard status == errSecSuccess else {
            logger?.log(level: .error, message: "CloudBackupKeyManager: SecRandomCopyBytes failed with status \(status)")
            throw KeyError.randomGenerationFailed
        }

        let passphrase = Data(randomBytes).base64EncodedString() + "!Aa0"

        do {
            try keychain.set(passphrase, key: Self.passphraseKey)
            logger?.log(level: .debug, message: "CloudBackupKeyManager: generated and stored new passphrase")
            return passphrase
        } catch {
            logger?.log(level: .error, message: "CloudBackupKeyManager: failed to store passphrase: \(error)")
            throw error
        }
    }

    func authenticateAndGetPassphrase() async throws -> String {
        try await authenticate()
        return try getOrCreatePassphrase()
    }

    func authenticateAndGetExistingPassphrase() async throws -> String {
        try await authenticate()
        guard let passphrase = try storedPassphrase() else {
            throw KeyError.passphraseNotFound
        }
        return passphrase
    }
}

extension CloudBackupKeyManager {
    enum KeyError: LocalizedError {
        case randomGenerationFailed
        case biometryNotAvailable
        case authenticationFailed
        case passphraseNotFound

        var errorDescription: String? {
            switch self {
            case .randomGenerationFailed: return "Failed to generate encryption key"
            case .biometryNotAvailable, .authenticationFailed: return "backup.cloud.biometry_required".localized
            case .passphraseNotFound: return "backup.cloud.key_not_synced".localized
            }
        }
    }
}
