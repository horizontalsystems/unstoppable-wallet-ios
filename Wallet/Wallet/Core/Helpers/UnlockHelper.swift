import Foundation

class UnlockHelper {
    static let shared = UnlockHelper()
    let pinKey = "pin_keychain_key"

    var locked = true

    var isPinned: Bool {
        let pin: String? = KeychainHelper.shared[pinKey]
        return pin != nil
    }

    func store(pin: String) throws {
        KeychainHelper.shared[pinKey] = pin
        if let error = KeychainHelper.shared.lastError {
            throw error
        }
    }

}
