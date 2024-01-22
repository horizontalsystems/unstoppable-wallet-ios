import Foundation

class Eip1559FeeSettingsViewModel: ObservableObject {
    private let decimalParser = AmountDecimalParser()

    @Published var maxFeeRateCautionState: CautionState = .none
    @Published var maxFeeRate: String = "" {
        didSet {
            validateMaxFeeRate()
        }
    }

    @Published var maxFeeCautionState: CautionState = .none
    @Published var maxFee: String = "" {
        didSet {
            validateMaxFeeRate()
        }
    }

    @Published var nonceCautionState: CautionState = .none
    @Published var nonce: String = "" {
        didSet {
            validateMaxFeeRate()
        }
    }

    private func validateMaxFeeRate() {
        guard let decimal = decimalParser.parseAnyDecimal(from: maxFeeRate) else {
            maxFeeRateCautionState = .caution(.init(text: "Can't recognize", type: .error))
            return
        }

        if decimal > 50 {
            maxFeeRateCautionState = .caution(.init(text: "Your transaction may be frontrun", type: .warning))
            return
        }

        maxFeeRateCautionState = .none
    }

    private func validateMaxFee() {
    }

    private func validateNonce() {
    }

}

extension Eip1559FeeSettingsViewModel {
    private func updateByStep(value: String?, direction: StepChangeButtonsViewDirection) -> Decimal? {
        guard let decimal = value.flatMap({ decimalParser.parseAnyDecimal(from: $0)}) else {
            return nil
        }
        // todo: we can recognize the smallest significand digit, and increase/decrease by smallest interval
        switch direction {
        case .down: return max(decimal - 1, 0)
        case .up: return decimal + 1
        }
    }

    func stepChangeMaxFeeRate(_ direction: StepChangeButtonsViewDirection) {
        if let newValue = updateByStep(value: maxFeeRate, direction: direction) {
            maxFeeRate = newValue.description
        }
    }
}