import BitcoinCore
import EvmKit
import Foundation
import MarketKit
import SwiftUI

class BitcoinFeeSettingsViewModel: ObservableObject {
    private let service: BitcoinTransactionService
    private let params: SendParameters

    @Published var satoshiPerByteCautionState: FieldCautionState = .none
    @Published var applyEnabled = false
    @Published var resetEnabled = false
    @Published var cautions = [CautionNew]()

    @Published var fee: Decimal?
    @Published var satoshiPerByte: Int? {
        didSet {
            sync()
        }
    }

    @Published private var _satoshiPerByteValue: String = ""
    var satoshiPerByteValue: Binding<String> {
        Binding(
            get: { self._satoshiPerByteValue },
            set: { newValue in
                self._satoshiPerByteValue = newValue
                self.handleChange()
            }
        )
    }

    init(service: BitcoinTransactionService, params: SendParameters) {
        self.service = service
        self.params = params
        satoshiPerByte = service.currentSatoshiPerByte

        if let satoshiPerByte {
            _satoshiPerByteValue = satoshiPerByte.description
        }
    }

    private func sync() {
        fee = try? service.resolveFee(params: params, satoshiPerByte: satoshiPerByte)

        applyEnabled = service.currentSatoshiPerByte != satoshiPerByte
        resetEnabled = service.recommendedSatoshiPerByte != satoshiPerByte

        cautions = BitcoinTransactionService.validate(actualFeeRates: service.actualFeeRates, satoshiPerByte: satoshiPerByte)

        if let caution = cautions.first {
            satoshiPerByteCautionState = .caution(caution.type)
        } else {
            satoshiPerByteCautionState = .none
        }
    }

    private func handleChange() {
        guard let satoshiPerByteInt = Int(_satoshiPerByteValue) else {
            satoshiPerByteCautionState = .caution(.error)
            return
        }

        satoshiPerByte = satoshiPerByteInt
    }

    private func updateByStep(value: Int, direction: StepChangeButtonsViewDirection) -> Int {
        switch direction {
        case .down: return max(value - 1, 0)
        case .up: return value + 1
        }
    }
}

extension BitcoinFeeSettingsViewModel {
    func stepChangesatoshiPerByte(_ direction: StepChangeButtonsViewDirection) {
        guard let satoshiPerByte else {
            return
        }

        satoshiPerByteValue.wrappedValue = updateByStep(value: satoshiPerByte, direction: direction).description
    }

    func onReset() {
        if let satoshiPerByte = service.recommendedSatoshiPerByte {
            _satoshiPerByteValue = satoshiPerByte.description
        }

        handleChange()
    }

    func apply() {
        guard let satoshiPerByte, let recommendedSatoshiPerByte = service.recommendedSatoshiPerByte else {
            return
        }

        service.set(satoshiPerByte: satoshiPerByte == recommendedSatoshiPerByte ? nil : satoshiPerByte)
    }
}
