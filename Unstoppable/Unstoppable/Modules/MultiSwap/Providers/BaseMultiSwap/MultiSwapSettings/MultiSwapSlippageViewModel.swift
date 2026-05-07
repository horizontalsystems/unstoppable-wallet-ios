import Combine
import Foundation
import MarketKit
import UIKit

class MultiSwapSlippageViewModel: ObservableObject {
    private let decimalParser = AmountDecimalParser()
    private let initialSlippage: Decimal

    @Published var slippageCautionState: CautionState = .none
    @Published var slippageString: String = "" {
        didSet {
            if slippageString == oldValue { return }

            if let decimal = decimalParser.parseAnyDecimal(from: slippageString) {
                slippage = decimal
            } else {
                slippage = 0
            }
        }
    }

    var slippage: Decimal {
        didSet {
            if slippage == oldValue { return }
            slippageString = slippage.description

            validateSlippage()
            sync()
        }
    }

    @Published var resetEnabled: Bool = false
    @Published var applyEnabled: Bool = false

    init(initialSlippage: Decimal) {
        self.initialSlippage = initialSlippage
        slippage = initialSlippage
        slippageString = slippage.description

        validateSlippage()
        sync()
    }

    private func validateSlippage() {
        slippageCautionState = MultiSwapSlippage.validate(slippage: slippage)
    }

    private func sync() {
        resetEnabled = slippage != MultiSwapSlippage.default
        applyEnabled = slippage != .zero && slippage != initialSlippage
    }
}

extension MultiSwapSlippageViewModel {
    func reset() {
        slippage = MultiSwapSlippage.default
    }

    func stepSlippage(direction: StepChangeButtonsViewDirection) {
        switch direction {
        case .down: slippage = max(slippage - 0.5, 0)
        case .up: slippage = slippage + 0.5
        }
    }
}

enum MultiSwapSlippage {
    static let `default`: Decimal = 1
    static var limitBounds: ClosedRange<Decimal> { 0.01 ... 50 }
    static let usualHighest: Decimal = 5

    enum SlippageError: Error, LocalizedError {
        case invalid
        case zeroValue
        case tooLow(min: Decimal)
        case tooHigh(max: Decimal)

        var errorDescription: String? {
            switch self {
            case .invalid: return "swap.advanced_settings.error.invalid_slippage".localized
            case .tooLow: return "swap.advanced_settings.error.lower_slippage".localized
            case let .tooHigh(max): return "swap.advanced_settings.error.higher_slippage".localized(max.description)
            default: return nil
            }
        }
    }

    static func validate(slippage: Decimal) -> CautionState {
        if slippage == .zero {
            return .caution(.init(
                text: MultiSwapSlippage.SlippageError.invalid.localizedDescription,
                type: .error
            )
            )
        }
        if slippage > MultiSwapSlippage.limitBounds.upperBound {
            return .caution(.init(
                text: SwapSettingsModule.SlippageError.tooHigh(
                    max: MultiSwapSlippage.limitBounds.upperBound
                ).localizedDescription,
                type: .error
            )
            )
        }
        if slippage < MultiSwapSlippage.limitBounds.lowerBound {
            return .caution(.init(
                text: SwapSettingsModule.SlippageError.tooLow(
                    min: MultiSwapSlippage.limitBounds.lowerBound
                ).localizedDescription,
                type: .error
            )
            )
        }
        if slippage >= MultiSwapSlippage.usualHighest {
            return .caution(.init(text: "swap.advanced_settings.warning.unusual_slippage".localized, type: .warning))
        }

        return .none
    }
}

extension CautionState {
    var valueLevel: ValueLevel {
        switch self {
        case .none: return .regular
        case let .caution(caution):
            switch caution.type {
            case .warning: return .warning
            case .error: return .error
            }
        }
    }
}
