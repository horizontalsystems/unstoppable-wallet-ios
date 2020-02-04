import Foundation
import StorageKit

class PinSecureStorage {
    private let storage: ISecureStorage

    private let pinKey = "pin_keychain_key"
    private let authDataKey = "auth_data_keychain_key"
    private let unlockAttemptsKey = "unlock_attempts_keychain_key"
    private let lockTimestampKey = "lock_timestamp_keychain_key"

    init(secureStorage: ISecureStorage) {
        storage = secureStorage
    }

}

extension PinSecureStorage: IPinSecureStorage {

    var pin: String? {
        storage.value(for: pinKey)
    }

    func set(pin: String?) throws {
        try storage.set(value: pin, for: pinKey)
    }

    var unlockAttempts: Int? {
        storage.value(for: unlockAttemptsKey)
    }

    func set(unlockAttempts: Int?) throws {
        try storage.set(value: unlockAttempts, for: unlockAttemptsKey)
    }

    var lockoutTimestamp: TimeInterval? {
        storage.value(for: lockTimestampKey)
    }

    func set(lockoutTimestamp: Double?) throws {
        try storage.set(value: lockoutTimestamp, for: lockTimestampKey)
    }

}
