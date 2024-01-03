import Foundation

struct MultiSwapSettingStorage {
    private var modifiedSettings = [Setting: Any]()

    var legacyGasPrice: Int? {
        get { modifiedSettings[.legacyGasPrice] as? Int }
        set { modifiedSettings[.legacyGasPrice] = newValue }
    }

    var slippage: Int? {
        get { modifiedSettings[.slippage] as? Int }
        set { modifiedSettings[.slippage] = newValue }
    }
}

extension MultiSwapSettingStorage {
    enum Setting {
        case legacyGasPrice
        case slippage
    }
}
