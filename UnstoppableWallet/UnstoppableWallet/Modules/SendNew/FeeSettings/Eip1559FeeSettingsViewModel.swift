import EvmKit
import Foundation
import MarketKit
import SwiftUI

class Eip1559FeeSettingsViewModel: ObservableObject {
    let service: EvmTransactionService
    private let feeViewItemFactory: FeeViewItemFactory
    private let decimalParser = AmountDecimalParser()

    init(service: EvmTransactionService, feeViewItemFactory: FeeViewItemFactory) {
        self.service = service
        self.feeViewItemFactory = feeViewItemFactory

        if case let .eip1559(recommendedMaxFeePerGas, _) = service.recommendedGasPrice {
            let baseStep = recommendedMaxFeePerGas.significant(depth: FeeViewItemFactory.stepDepth)
            baseFee = feeViewItemFactory.description(value: recommendedMaxFeePerGas, step: baseStep)
        }

        syncFromService()
    }

    @Published var baseFee: String?
    @Published var maxFeeCautionState: FieldCautionState = .none
    @Published var maxTipsCautionState: FieldCautionState = .none

    @Published private var _maxFee: String = ""
    var maxFee: Binding<String> {
        Binding(
            get: { self._maxFee },
            set: { newValue in
                self._maxFee = newValue
                self.handleChange()
            }
        )
    }

    @Published private var _maxTips: String = ""
    var maxTips: Binding<String> {
        Binding(
            get: { self._maxTips },
            set: { newValue in
                self._maxTips = newValue
                self.handleChange()
            }
        )
    }

    @Published var resetEnabled = false

    private func syncFromService() {
        if case let .eip1559(maxFee, maxTips) = service.gasPrice {
            _maxFee = feeViewItemFactory.decimalValue(value: maxFee).description
            _maxTips = feeViewItemFactory.decimalValue(value: maxTips).description
        }

        sync()
    }

    private func sync() {
        resetEnabled = service.modified

        if service.warnings.contains(where: { $0 is EvmFeeModule.GasDataWarning }) {
            maxFeeCautionState = .caution(.warning)
            maxTipsCautionState = .caution(.warning)
        } else {
            maxFeeCautionState = .none
            maxTipsCautionState = .none
        }
    }

    private func handleChange() {
        guard let maxFeeDecimal = decimalParser.parseAnyDecimal(from: _maxFee),
              let maxTipsDecimal = decimalParser.parseAnyDecimal(from: _maxTips)
        else {
            maxFeeCautionState = .caution(.error)
            maxTipsCautionState = .caution(.error)
            return
        }

        service.set(gasPrice: .eip1559(
            maxFeePerGas: feeViewItemFactory.intValue(value: maxFeeDecimal),
            maxPriorityFeePerGas: feeViewItemFactory.intValue(value: maxTipsDecimal)
        ))

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

extension Eip1559FeeSettingsViewModel {
    func stepChangeMaxFee(_ direction: StepChangeButtonsViewDirection) {
        if let newValue = updateByStep(value: _maxFee, direction: direction) {
            maxFee.wrappedValue = newValue.description
        }
    }

    func stepChangeMaxTips(_ direction: StepChangeButtonsViewDirection) {
        if let newValue = updateByStep(value: _maxTips, direction: direction) {
            maxTips.wrappedValue = newValue.description
        }
    }

    func onReset() {
        service.useRecommended()
        syncFromService()
    }
}
