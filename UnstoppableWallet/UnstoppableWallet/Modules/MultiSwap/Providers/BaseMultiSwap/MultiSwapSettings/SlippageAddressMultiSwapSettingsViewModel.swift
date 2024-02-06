import Foundation
import MarketKit
import UIKit

class SlippageAddressMultiSwapSettingsViewModel: AddressMultiSwapSettingsViewModel {
    private let decimalParser = AmountDecimalParser()

    @Published var slippageCautionState: CautionState = .none {
        didSet {
            syncButtons()
        }
    }

    @Published var slippage: String = "" {
        didSet {
            validateSlippage()
        }
    }

    override init(storage: MultiSwapSettingStorage, blockchainType: BlockchainType) {
        super.init(storage: storage, blockchainType: blockchainType)

        slippage = initialSlippage?.description ?? ""
    }

    private func validateSlippage() {
        guard !slippage.isEmpty else {
            slippageCautionState = .none
            return
        }

        guard let decimal = decimalParser.parseAnyDecimal(from: slippage) else {
            slippageCautionState = .caution(.init(text: MultiSwapSlippage.SlippageError.invalid.localizedDescription, type: .error))
            return
        }

        slippageCautionState = MultiSwapSlippage.validate(slippage: decimal)
    }

    override var fields: [BaseMultiSwapSettingsViewModel.FieldState] {
        super.fields + [MultiSwapSlippage.state(initial: initialSlippage, value: slippage)]
    }

    override func onReset() {
        super.onReset()

        slippage = ""
    }

    override func onDone() {
        super.onDone()

        if slippage.isEmpty {
            storage.set(value: nil, for: MultiSwapSettingStorage.LegacySetting.slippage)
        } else if let slippage = decimalParser.parseAnyDecimal(from: slippage), slippage != initialSlippage {
            storage.set(value: slippage, for: MultiSwapSettingStorage.LegacySetting.slippage)
        }
    }
}

extension SlippageAddressMultiSwapSettingsViewModel {
    var initialSlippage: Decimal? {
        storage.value(for: MultiSwapSettingStorage.LegacySetting.slippage)
    }

    var slippageShortCuts: [ShortCutButtonType] {
        MultiSwapSlippage.recommended.map { $0.description + "%" }.map { .text($0) }
    }

    func slippage(at index: Int) -> Decimal {
        MultiSwapSlippage.recommended.at(index: index) ??
                MultiSwapSlippage.recommended[0]
    }
}

enum MultiSwapSlippage {
    static let `default`: Decimal = 1
    static let recommended: [Decimal] = [0.1, 3]
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
        return .none
    }

    static func state(initial: Decimal?, value: String) -> BaseMultiSwapSettingsViewModel.FieldState {
        let initial = initial ?? `default`

        if value.isEmpty {
            return .init(doneEnabled: initial != MultiSwapSlippage.`default`, resetEnabled: false)
        }

        if let slippage = AmountDecimalParser().parseAnyDecimal(from: value) {
            return .init(doneEnabled: slippage != initial, resetEnabled: true)
        } else {
            return .init(doneEnabled: false, resetEnabled: true)
        }
    }
}
