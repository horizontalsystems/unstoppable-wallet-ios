import Foundation

class UnlockHelper {
    static let shared = UnlockHelper()
    let pinKey = "pin_keychain_key"

    var isPinned: Bool {
        return KeychainHelper.shared.getString(pinKey) != nil
    }

    func store(pin: String?) throws {
        try KeychainHelper.shared.set(pin, key: pinKey)
    }

    func validate(_ pin: String) -> Bool {
        return KeychainHelper.shared.getString(pinKey) == pin
    }

}
