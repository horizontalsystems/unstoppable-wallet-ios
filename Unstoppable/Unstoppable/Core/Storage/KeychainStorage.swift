import Foundation
import HsToolKit
import KeychainAccess

class KeychainStorage {
    private let keychain: Keychain
    private let logger: Logger

    init(service: String, logger: Logger) {
        keychain = Keychain(service: service).accessibility(.whenPasscodeSetThisDeviceOnly)
        self.logger = logger
    }
}

extension KeychainStorage {
    func value<T: LosslessStringConvertible>(for key: String) -> T? {
        do {
            let result = try keychain.getString(key)
            return result.flatMap { T($0) }
        } catch {
            logger.log(level: .error, message: "Keychain 'GET' for \(key) failed due to: \(String(reflecting: error))", context: ["Keychain"], save: true)
            return nil
        }
    }

    func set(value: (some LosslessStringConvertible)?, for key: String) throws {
        do {
            if let value {
                try keychain.set(value.description, key: key)
            } else {
                try keychain.remove(key)
            }
        } catch {
            logger.log(level: .error, message: "Keychain 'SET' for \(key) failed due to: \(String(reflecting: error))", context: ["Keychain"], save: true)
            throw error
        }
    }

    func value(for key: String) -> Data? {
        do {
            return try keychain.getData(key)
        } catch {
            logger.log(level: .error, message: "Keychain 'GET' for \(key) failed due to: \(String(reflecting: error))", context: ["Keychain"], save: true)
            return nil
        }
    }

    func set(value: Data?, for key: String) throws {
        do {
            if let value {
                try keychain.set(value, key: key)
            } else {
                try keychain.remove(key)
            }
        } catch {
            logger.log(level: .error, message: "Keychain 'SET' for \(key) failed due to: \(String(reflecting: error))", context: ["Keychain"], save: true)
            throw error
        }
    }

    func removeValue(for key: String) throws {
        do {
            try keychain.remove(key)
        } catch {
            logger.log(level: .error, message: "Keychain 'REMOVE' for \(key) failed due to: \(String(reflecting: error))", context: ["Keychain"], save: true)
            throw error
        }
    }

    func clear() throws {
        do {
            try keychain.removeAll()
        } catch {
            logger.log(level: .error, message: "Keychain 'CLEAR' failed due to: \(String(reflecting: error))", context: ["Keychain"], save: true)
            throw error
        }
    }
}
