import Foundation
import MarketKit
import UIKit

class OneInchMultiSwapSettingsViewModel: ObservableObject {
    private let decimalParser = AmountDecimalParser()
    let storage: MultiSwapSettingStorage
    let blockchainType: BlockchainType

    @Published var addressResult: AddressInput.Result = .idle {
        didSet {
            switch addressResult {
            case let .invalid(failure): addressCautionState = .caution(.init(text: failure.error.localizedDescription, type: .error))
            default: addressCautionState = .none
            }
        }
    }

    @Published var addressCautionState: CautionState = .none
    @Published var address: String = "" {
        didSet { print("OneInchMultiSwapSettingsViewModel didSet: \(address)")}
    }

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

    @Published var resetEnabled = true
    @Published var doneEnabled = true

    @Published var qrScanPresented = false

    init(storage: MultiSwapSettingStorage, blockchainType: BlockchainType) {
        self.storage = storage
        self.blockchainType = blockchainType

        print("Set Initial value: on INIT : MaxFuck")
        address = initialAddress
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

    private func syncButtons() {
        if slippageCautionState == .none, addressCautionState == .none {
            doneEnabled = true
        } else {
            doneEnabled = false
        }
    }
}

extension OneInchMultiSwapSettingsViewModel {
    var initialAddress: String {
        "0x6150096B0D2ebCec98d1C981788c61d8B9ca3B22"//storage.value(for: MultiSwapSettingStorage.LegacySetting.address)
    }

    var initialSlippage: Decimal {
        storage.value(for: MultiSwapSettingStorage.LegacySetting.slippage) ?? MultiSwapSlippage.defaultSlippage
    }

    var slippageShortCuts: [ShortCutButtonType] {
        MultiSwapSlippage.recommendedSlippages.map { $0.description + "%" }.map { .text($0) }
    }

    func slippage(at index: Int) -> Decimal {
        MultiSwapSlippage.recommendedSlippages.at(index: index) ??
                MultiSwapSlippage.recommendedSlippages[0]
    }

    func onReset() {
        // how to set address!
        slippage = ""
    }

    func onDone() {}
}

extension OneInchMultiSwapSettingsViewModel {
    enum Section: Int {
        case address, slippage
    }
}

enum MultiSwapSlippage {
    static let defaultSlippage: Decimal = 1
    static let recommendedSlippages: [Decimal] = [0.1, 3]
    static var limitSlippageBounds: ClosedRange<Decimal> { 0.01 ... 50 }
    static let usualHighestSlippage: Decimal = 5

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
        if slippage > MultiSwapSlippage.limitSlippageBounds.upperBound {
            return .caution(.init(
                text: SwapSettingsModule.SlippageError.tooHigh(
                    max: MultiSwapSlippage.limitSlippageBounds.upperBound
                ).localizedDescription,
                type: .error
            )
            )
        }
        if slippage < MultiSwapSlippage.limitSlippageBounds.lowerBound {
            return .caution(.init(
                text: SwapSettingsModule.SlippageError.tooLow(
                    min: MultiSwapSlippage.limitSlippageBounds.lowerBound
                ).localizedDescription,
                type: .error
            )
            )
        }
        return .none
    }
}
