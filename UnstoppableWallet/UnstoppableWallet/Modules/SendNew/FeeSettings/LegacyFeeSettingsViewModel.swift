import EvmKit
import Foundation
import MarketKit
import SwiftUI

class LegacyFeeSettingsViewModel: ObservableObject {
    private let service: EvmTransactionService
    private let feeViewItemFactory: FeeViewItemFactory
    private let decimalParser = AmountDecimalParser()

    @Published var gasPriceCautionState: FieldCautionState = .none
    @Published var applyEnabled = false
    @Published var resetEnabled = false
    @Published var cautions = [CautionNew]()

    @Published var gasPrice: GasPrice? {
        didSet {
            sync()
        }
    }

    @Published private var _gasPriceValue: String = ""
    var gasPriceValue: Binding<String> {
        Binding(
            get: { self._gasPriceValue },
            set: { newValue in
                self._gasPriceValue = newValue
                self.handleChange()
            }
        )
    }

    init(service: EvmTransactionService, feeViewItemFactory: FeeViewItemFactory) {
        self.service = service
        self.feeViewItemFactory = feeViewItemFactory
        gasPrice = service.currentGasPrice

        if case let .legacy(gasPrice) = gasPrice {
            _gasPriceValue = feeViewItemFactory.decimalValue(value: gasPrice).description
        }
    }

    private func sync() {
        applyEnabled = service.currentGasPrice != gasPrice
        resetEnabled = service.recommendedGasPrice != gasPrice

        let warnings = EvmTransactionService.validateGasPrice(recommended: service.recommendedGasPrice, current: gasPrice)
        cautions = warnings.map(\.caution)

        if !warnings.isEmpty {
            gasPriceCautionState = .caution(.warning)
        } else {
            gasPriceCautionState = .none
        }
    }

    private func handleChange() {
        guard let gasPriceDecimal = decimalParser.parseAnyDecimal(from: _gasPriceValue) else {
            gasPriceCautionState = .caution(.error)
            return
        }

        gasPrice = .legacy(gasPrice: feeViewItemFactory.intValue(value: gasPriceDecimal))
    }

    private func updateByStep(value: String?, direction: StepChangeButtonsViewDirection) -> Decimal? {
        guard let decimal = value.flatMap({ decimalParser.parseAnyDecimal(from: $0) }) else {
            return nil
        }

        return feeViewItemFactory.updated(value: decimal, percent: 10, direction: direction)
    }
}

extension LegacyFeeSettingsViewModel {
    func stepChangeGasPrice(_ direction: StepChangeButtonsViewDirection) {
        if let newValue = updateByStep(value: _gasPriceValue, direction: direction) {
            gasPriceValue.wrappedValue = newValue.description
        }
    }

    func onReset() {
        if case let .legacy(gasPrice) = service.recommendedGasPrice {
            _gasPriceValue = feeViewItemFactory.decimalValue(value: gasPrice).description
            handleChange()
        }
    }

    func apply() {
        guard let gasPrice, let recommendedGasPrice = service.recommendedGasPrice else {
            return
        }

        service.set(gasPrice: gasPrice == recommendedGasPrice ? nil : gasPrice)
    }
}
