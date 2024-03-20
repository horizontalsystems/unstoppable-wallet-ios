import Combine
import Foundation
import MarketKit
import UIKit

class SlippageMultiSwapSettingsViewModel: ObservableObject, IMultiSwapSettingsField {
    private let decimalParser = AmountDecimalParser()
    var storage: MultiSwapSettingStorage
    var syncSubject = PassthroughSubject<Void, Never>()

    @Published var slippageCautionState: CautionState = .none
    @Published var slippageString: String = "" {
        didSet {
            if slippageString == oldValue { return }
            guard let decimal = decimalParser.parseAnyDecimal(from: slippageString) else {
                slippage = nil
                return
            }
            slippage = decimal
        }
    }

    var slippage: Decimal? = nil {
        didSet {
            if slippage == oldValue { return }
            slippageString = slippage?.description ?? ""
            syncSubject.send()
            validateSlippage()
        }
    }

    init(storage: MultiSwapSettingStorage) {
        self.storage = storage

        slippage = initialSlippage
        slippageString = slippage?.description ?? ""
    }

    private func validateSlippage() {
        guard let slippage else {
            slippageCautionState = .none
            return
        }

        slippageCautionState = MultiSwapSlippage.validate(slippage: slippage)
    }

    var state: BaseMultiSwapSettingsViewModel.FieldState {
        MultiSwapSlippage.state(initial: initialSlippage, value: slippage)
    }

    func onReset() {
        slippage = nil
    }

    func onDone() {
        if slippage == nil {
            storage.set(value: nil, for: MultiSwapSettingStorage.LegacySetting.slippage)
        } else if let slippage, slippage != initialSlippage {
            storage.set(value: slippage, for: MultiSwapSettingStorage.LegacySetting.slippage)
        }
    }
}

extension SlippageMultiSwapSettingsViewModel {
    var syncPublisher: AnyPublisher<Void, Never> {
        syncSubject.eraseToAnyPublisher()
    }

    var initialSlippage: Decimal? {
        storage.value(for: MultiSwapSettingStorage.LegacySetting.slippage)
    }

    func stepSlippage(direction: StepChangeButtonsViewDirection) {
        switch direction {
        case .down: slippage = max((slippage ?? MultiSwapSlippage.default) - 0.5, 0)
        case .up: slippage = (slippage ?? MultiSwapSlippage.default) + 0.5
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
        if slippage > MultiSwapSlippage.usualHighest {
            return .caution(.init(text: "swap.advanced_settings.warning.unusual_slippage".localized, type: .warning))
        }

        return .none
    }

    static func state(initial: Decimal?, value: Decimal?) -> BaseMultiSwapSettingsViewModel.FieldState {
        let changed = value != initial
        let slippage = value ?? `default`
        let valid = slippage < Self.limitBounds.upperBound
        let resetEnabled = slippage != `default`

        return .init(valid: valid, changed: changed, resetEnabled: resetEnabled)
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
