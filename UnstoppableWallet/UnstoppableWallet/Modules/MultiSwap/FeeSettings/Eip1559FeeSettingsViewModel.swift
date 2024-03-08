import EvmKit
import Foundation
import MarketKit

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

        sync()
    }

    @Published var baseFee: String = ""
    @Published var maxFeeCautionState: FieldCautionState = .none
    @Published var maxFee: String = ""
    @Published var maxTipsCautionState: FieldCautionState = .none
    @Published var maxTips: String = ""
    @Published var nonceCautionState: FieldCautionState = .none
    @Published var nonce: String = ""
    @Published var resetEnabled = false

    private func sync() {
        if case let .eip1559(maxFee, maxTips) = service.gasPrice {
            self.maxFee = feeViewItemFactory.decimalValue(value: maxFee).description
            self.maxTips = feeViewItemFactory.decimalValue(value: maxTips).description
        }

        nonce = "\(service.nonce ?? 0)"
        resetEnabled = service.modified

        if service.warnings.contains(where: { $0 is EvmFeeModule.GasDataWarning }) {
            maxFeeCautionState = .caution(.warning)
            maxTipsCautionState = .caution(.warning)
        } else {
            maxFeeCautionState = .none
            maxTipsCautionState = .none
        }

        if service.errors.contains(where: { $0 is NonceService.NonceError }) {
            nonceCautionState = .caution(.error)
        } else {
            nonceCautionState = .none
        }
    }

    private func handleGasPrice() {
        guard let maxFeeDecimal = decimalParser.parseAnyDecimal(from: maxFee),
              let maxTipsDecimal = decimalParser.parseAnyDecimal(from: maxTips)
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

    private func handleNonce() {
        guard let intNonce = Int(nonce) else {
            nonceCautionState = .caution(.error)
            return
        }

        service.set(nonce: intNonce)
        sync()
    }

    private func updateByStep(value: String?, direction: StepChangeButtonsViewDirection) -> Decimal? {
        guard let decimal = value.flatMap({ decimalParser.parseAnyDecimal(from: $0) }) else {
            return nil
        }
        // TODO: we can recognize the smallest significand digit, and increase/decrease by smallest interval
        switch direction {
        case .down: return max(decimal - 1, 0)
        case .up: return decimal + 1
        }
    }
}

extension Eip1559FeeSettingsViewModel {
    func stepChangeMaxFee(_ direction: StepChangeButtonsViewDirection) {
        if let newValue = updateByStep(value: maxFee, direction: direction) {
            maxFee = newValue.description
            handleGasPrice()
        }
    }

    func stepChangeMaxTips(_ direction: StepChangeButtonsViewDirection) {
        if let newValue = updateByStep(value: maxTips, direction: direction) {
            maxTips = newValue.description
            handleGasPrice()
        }
    }

    func stepChangeNonce(_ direction: StepChangeButtonsViewDirection) {
        if let newValue = updateByStep(value: nonce, direction: direction) {
            nonce = newValue.description
            handleNonce()
        }
    }

    func onReset() {
        service.useRecommended()
        sync()
    }
}
