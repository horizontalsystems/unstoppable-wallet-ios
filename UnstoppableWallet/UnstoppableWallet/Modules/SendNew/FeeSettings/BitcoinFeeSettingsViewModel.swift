import EvmKit
import Foundation
import MarketKit
import SwiftUI

class BitcoinFeeSettingsViewModel: ObservableObject {
    let service: BitcoinTransactionService

    init(service: BitcoinTransactionService) {
        self.service = service

        if let satoshiPerByte = service.actualFeeRates?.recommended {
            _satoshiPerByte = satoshiPerByte.description
        }

        syncFromService()
    }

    @Published private var _satoshiPerByte: String = ""
    var satoshiPerByte: Binding<String> {
        Binding(
            get: { self._satoshiPerByte },
            set: { newValue in
                self._satoshiPerByte = newValue
                self.handleChange()
            }
        )
    }

    @Published var satoshiPerByteCautionState: FieldCautionState = .none
    @Published var resetEnabled = false

    private func syncFromService() {
        if let satoshiPerByte = service.satoshiPerByte {
            _satoshiPerByte = satoshiPerByte.description
        }

        sync()
    }

    private func sync() {
        resetEnabled = service.modified

        if let caution = service.cautions.first {
            satoshiPerByteCautionState = .caution(caution.type)
        } else {
            satoshiPerByteCautionState = .none
        }
    }

    private func handleChange() {
        guard let satoshiPerByteInt = Int(_satoshiPerByte) else {
            satoshiPerByteCautionState = .caution(.error)
            return
        }

        service.set(satoshiPerByte: satoshiPerByteInt)

        sync()
    }

    private func updateByStep(value: String?, direction: StepChangeButtonsViewDirection) -> Int? {
        guard let int = value.flatMap({ Int($0) }) else {
            return nil
        }

        switch direction {
        case .down: return max(int - 1, 0)
        case .up: return int + 1
        }
    }
}

extension BitcoinFeeSettingsViewModel {
    func stepChangesatoshiPerByte(_ direction: StepChangeButtonsViewDirection) {
        if let newValue = updateByStep(value: _satoshiPerByte, direction: direction) {
            satoshiPerByte.wrappedValue = newValue.description
        }
    }

    func onReset() {
        service.useRecommended()
        syncFromService()
    }
}
