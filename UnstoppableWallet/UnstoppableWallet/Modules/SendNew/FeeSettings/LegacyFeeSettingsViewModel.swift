import EvmKit
import Foundation
import MarketKit
import SwiftUI

class LegacyFeeSettingsViewModel: ObservableObject {
    let service: EvmTransactionService
    private let feeViewItemFactory: FeeViewItemFactory
    private let decimalParser = AmountDecimalParser()

    init(service: EvmTransactionService, feeViewItemFactory: FeeViewItemFactory) {
        self.service = service
        self.feeViewItemFactory = feeViewItemFactory

        syncFromService()
    }

    @Published var gasPriceCautionState: FieldCautionState = .none

    @Published private var _gasPrice: String = ""
    var gasPrice: Binding<String> {
        Binding(
            get: { self._gasPrice },
            set: { newValue in
                self._gasPrice = newValue
                self.handleChange()
            }
        )
    }

    @Published var resetEnabled = false

    private func syncFromService() {
        if case let .legacy(gasPrice) = service.gasPrice {
            _gasPrice = feeViewItemFactory.decimalValue(value: gasPrice).description
        }

        sync()
    }

    private func sync() {
        resetEnabled = service.modified

        if service.warnings.contains(where: { $0 is EvmFeeModule.GasDataWarning }) {
            gasPriceCautionState = .caution(.warning)
        } else {
            gasPriceCautionState = .none
        }
    }

    private func handleChange() {
        guard let gasPriceDecimal = decimalParser.parseAnyDecimal(from: _gasPrice) else {
            gasPriceCautionState = .caution(.error)
            return
        }

        service.set(gasPrice: .legacy(gasPrice: feeViewItemFactory.intValue(value: gasPriceDecimal)))

        sync()
    }

    private func updateByStep(value: String?, direction: StepChangeButtonsViewDirection) -> Decimal? {
        guard let decimal = value.flatMap({ decimalParser.parseAnyDecimal(from: $0) }) else {
            return nil
        }

        let diff = decimal * 10 / 100

        switch direction {
        case .down: return max(decimal - diff, 0)
        case .up: return decimal + diff
        }
    }
}

extension LegacyFeeSettingsViewModel {
    func stepChangeGasPrice(_ direction: StepChangeButtonsViewDirection) {
        if let newValue = updateByStep(value: _gasPrice, direction: direction) {
            gasPrice.wrappedValue = newValue.description
        }
    }

    func onReset() {
        service.useRecommended()
        syncFromService()
    }
}
