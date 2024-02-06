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

        doneEnabled = fields.map { $0.doneEnabled }.contains(true)
        resetEnabled = fields.map { $0.resetEnabled }.contains(true)
    }

    func onReset() {}
    func onDone() {}
}

extension BaseMultiSwapSettingsViewModel {
    struct FieldState {
        let doneEnabled: Bool
        let resetEnabled: Bool
    }
}
