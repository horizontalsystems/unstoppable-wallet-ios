import Foundation
import KeychainAccess

protocol Keychainable {
    associatedtype T
    func code() -> String
    static func decode(_ value: String?) -> T?
}

class KeychainHelper {
    static let shared = KeychainHelper()

    let keychain = Keychain(service: "io.horizontalsystems.bank.dev")

    private var _lastError: Error?
    var lastError: Error? {
        get {
            let tempError = _lastError
            _lastError = nil
            return tempError
        }
    }

    subscript<T: Keychainable>(key: String) -> T? {
        get {
            return T.decode(keychain[key]) as? T
        }
        set {
            _lastError = nil
            do {
                if let value = newValue?.code() {
                    try keychain.set(value, key: key)
                } else {
                    try keychain.remove(key)
                }
            } catch {
                _lastError = error
            }
        }
    }

}

extension Bool: Keychainable {
    typealias T = Bool

    func code() -> String {
        return self ? "true" : "false"
    }

    static func decode(_ value: String?) -> T? {
        return value == "true"
    }

}

extension String: Keychainable {
    typealias T = String

    func code() -> String {
        return self
    }

    static func decode(_ value: String?) -> T? {
        return value
    }

}
