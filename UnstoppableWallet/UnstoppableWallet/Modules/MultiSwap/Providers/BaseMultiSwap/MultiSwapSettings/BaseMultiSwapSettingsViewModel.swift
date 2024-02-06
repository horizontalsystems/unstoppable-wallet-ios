import Foundation
import MarketKit
import UIKit

class BaseMultiSwapSettingsViewModel: ObservableObject {
    var storage: MultiSwapSettingStorage

    @Published var resetEnabled = false
    @Published var doneEnabled = false

    init(storage: MultiSwapSettingStorage) {
        self.storage = storage
    }

    var fields: [FieldState] { [] }
    func syncButtons() {
        let fields = fields

        let allValid = fields.map { $0.valid }.allSatisfy { $0 }
        let anyChanged = fields.map { $0.changed }.contains(true)

        doneEnabled = allValid && anyChanged
        resetEnabled = fields.map { $0.resetEnabled }.contains(true)
    }

    func onReset() {}
    func onDone() {}
}

extension BaseMultiSwapSettingsViewModel {
    struct FieldState {
        let valid: Bool
        let changed: Bool
        let resetEnabled: Bool
    }
}
