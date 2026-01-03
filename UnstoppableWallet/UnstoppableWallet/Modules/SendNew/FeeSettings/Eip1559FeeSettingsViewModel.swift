import EvmKit
import Foundation
import MarketKit
import SwiftUI

class Eip1559FeeSettingsViewModel: ObservableObject {
    private let service: EvmTransactionService
    private let feeViewItemFactory: FeeViewItemFactory
    private let decimalParser = AmountDecimalParser()

    @Published var baseFee: String?
    @Published var maxFeeCautionState: FieldCautionState = .none
    @Published var maxTipsCautionState: FieldCautionState = .none
    @Published var applyEnabled = false
    @Published var resetEnabled = false
    @Published var cautions = [CautionNew]()

    @Published var gasPrice: GasPrice? {
        didSet {
            sync()
        }
    }

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

    init(service: EvmTransactionService, feeViewItemFactory: FeeViewItemFactory) {
        self.service = service
        self.feeViewItemFactory = feeViewItemFactory
        gasPrice = service.currentGasPrice

        if case let .eip1559(recommendedMaxFeePerGas, _) = service.recommendedGasPrice {
            let baseStep = recommendedMaxFeePerGas.significant(depth: FeeViewItemFactory.stepDepth)
            baseFee = feeViewItemFactory.description(value: recommendedMaxFeePerGas, step: baseStep)
        }

        if case let .eip1559(maxFee, maxTips) = gasPrice {
            _maxFee = feeViewItemFactory.decimalValue(value: maxFee).description
            _maxTips = feeViewItemFactory.decimalValue(value: maxTips).description
        }
    }

    private func sync() {
        applyEnabled = service.currentGasPrice != gasPrice
        resetEnabled = service.recommendedGasPrice != gasPrice

        let warnings = EvmTransactionService.validateGasPrice(recommended: service.recommendedGasPrice, current: gasPrice)
        cautions = warnings.map(\.caution)

        if !warnings.isEmpty {
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

        gasPrice = .eip1559(
            maxFeePerGas: feeViewItemFactory.intValue(value: maxFeeDecimal),
            maxPriorityFeePerGas: feeViewItemFactory.intValue(value: maxTipsDecimal)
        )
    }

    private func updateByStep(value: String?, direction: StepChangeButtonsViewDirection) -> Decimal? {
        guard let decimal = value.flatMap({ decimalParser.parseAnyDecimal(from: $0) }) else {
            return nil
        }

        return feeViewItemFactory.updated(value: decimal, percent: 10, direction: direction)
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
        if case let .eip1559(maxFee, maxTips) = service.recommendedGasPrice {
            _maxFee = feeViewItemFactory.decimalValue(value: maxFee).description
            _maxTips = feeViewItemFactory.decimalValue(value: maxTips).description
        }

        handleChange()
    }

    func apply() {
        guard let gasPrice, let recommendedGasPrice = service.recommendedGasPrice else {
            return
        }

        service.set(gasPrice: gasPrice == recommendedGasPrice ? nil : gasPrice)
    }
}
