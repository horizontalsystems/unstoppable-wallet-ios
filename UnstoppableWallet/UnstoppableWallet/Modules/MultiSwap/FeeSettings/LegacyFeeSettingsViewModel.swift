import EvmKit
import Foundation
import MarketKit

class LegacyFeeSettingsViewModel: ObservableObject {
    let service: EvmTransactionService
    private let feeViewItemFactory: FeeViewItemFactory
    private let decimalParser = AmountDecimalParser()

    init(service: EvmTransactionService, feeViewItemFactory: FeeViewItemFactory) {
        self.service = service
        self.feeViewItemFactory = feeViewItemFactory

        sync()
    }

    @Published var gasPriceCautionState: FieldCautionState = .none
    @Published var gasPrice: String = ""
    @Published var nonceCautionState: FieldCautionState = .none
    @Published var nonce: String = ""
    @Published var resetEnabled = false

    private func sync() {
        if case let .legacy(gasPrice) = service.gasPrice {
            self.gasPrice = feeViewItemFactory.decimalValue(value: gasPrice).description
        }

        nonce = "\(service.nonce ?? 0)"
        resetEnabled = service.modified

        if service.warnings.contains(where: { $0 is EvmFeeModule.GasDataWarning }) {
            gasPriceCautionState = .caution(.warning)
        } else {
            gasPriceCautionState = .none
        }

        if service.errors.contains(where: { $0 is NonceService.NonceError }) {
            nonceCautionState = .caution(.error)
        } else {
            nonceCautionState = .none
        }
    }

    private func handleGasPrice() {
        guard let gasPriceDecimal = decimalParser.parseAnyDecimal(from: gasPrice) else {
            gasPriceCautionState = .caution(.error)
            return
        }

        service.set(gasPrice: .legacy(gasPrice: feeViewItemFactory.intValue(value: gasPriceDecimal)))
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

extension LegacyFeeSettingsViewModel {
    func stepChangeGasPrice(_ direction: StepChangeButtonsViewDirection) {
        if let newValue = updateByStep(value: gasPrice, direction: direction) {
            gasPrice = newValue.description
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
