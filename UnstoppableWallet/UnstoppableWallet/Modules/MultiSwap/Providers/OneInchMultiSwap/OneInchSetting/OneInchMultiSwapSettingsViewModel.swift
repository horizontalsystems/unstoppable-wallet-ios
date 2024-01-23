import Foundation

class OneInchMultiSwapSettingsViewModel: ObservableObject {
    private let decimalParser = AmountDecimalParser()
    let storage: MultiSwapSettingStorage

    @Published var addressCautionState: CautionState = .none
    @Published var address: String = "" {
        didSet {
            validateAddress()
        }
    }

    @Published var slippageCautionState: CautionState = .none
    @Published var slippage: String = "" {
        didSet {
            validateSlippage()
        }
    }

    @Published var applyEnabled = false

    init(storage: MultiSwapSettingStorage) {
        self.storage = storage
    }

    private func validateAddress() {
    }

    private func validateSlippage() {
        guard let decimal = decimalParser.parseAnyDecimal(from: slippage) else {
            slippageCautionState = .caution(.init(text: "Can't recognize", type: .error))
            return
        }

        if decimal > 50 {
            slippageCautionState = .caution(.init(text: "Your transaction may be frontrun", type: .warning))
            return
        }

        slippageCautionState = .none
    }
}

extension OneInchMultiSwapSettingsViewModel {
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

    func stepChangeSlippage(_ direction: StepChangeButtonsViewDirection) {
        if let newValue = updateByStep(value: slippage, direction: direction) {
            slippage = newValue.description
        }
    }

    func onApply() {
    }
}

extension OneInchMultiSwapSettingsViewModel {
    enum Section: Int {
        case address, slippage
    }
}