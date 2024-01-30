import Foundation

class MultiSwapSettingStorage {
    private var modifiedSettings = [String: Any]()

    func value<T>(for key: String) -> T? {
        modifiedSettings[key] as? T
    }

    func set(value: Any?, for key: String) {
        if let value {
            modifiedSettings[key] = value
        } else {
            modifiedSettings[key] = nil
        }
    }

    var isModified: Bool { !modifiedSettings.isEmpty }
}

extension MultiSwapSettingStorage {
    enum LegacySetting {
        static let address = "recipient"
        static let slippage = "slippage"
    }
}
