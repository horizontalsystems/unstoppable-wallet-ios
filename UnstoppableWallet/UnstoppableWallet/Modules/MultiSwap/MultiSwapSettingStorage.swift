import Foundation

struct MultiSwapSettingStorage {
    private var modifiedSettings = [String: Any]()

    func value<T>(for key: String) -> T? {
        modifiedSettings[key] as? T
    }

    mutating func set(value: (some Any)?, for key: String) {
        if let value {
            modifiedSettings[key] = value
        } else {
            modifiedSettings[key] = nil
        }
    }
}

extension MultiSwapSettingStorage {
    enum LegacySetting {
        static let address = "recipient"
        static let slippage = "slippage"
    }
}
