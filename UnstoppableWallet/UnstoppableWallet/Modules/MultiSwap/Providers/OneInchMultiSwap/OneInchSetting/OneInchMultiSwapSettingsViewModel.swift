import Foundation
import MarketKit
import UIKit

class OneInchMultiSwapSettingsViewModel: ObservableObject {
    private let decimalParser = AmountDecimalParser()
    let storage: MultiSwapSettingStorage

    @Published var blockchainType: BlockchainType? = nil
    @Published var addressResult: AddressInput.Result = .idle

    @Published var addressCautionState: CautionState = .none
    @Published var address: String = "" {
        didSet {
            validateAddress()
        }
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

    @Published var resetEnabled = false
    @Published var doneEnabled = true

    @Published var qrScanPresented = false

    init(storage: MultiSwapSettingStorage) {
        self.storage = storage
    }

    private func validateAddress() {}

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
        storage.value(for: MultiSwapSettingStorage.LegacySetting.address) ?? ""
    }

    var initialSlippage: Decimal {
        storage.value(for: MultiSwapSettingStorage.LegacySetting.slippage) ?? MultiSwapSlippage.defaultSlippage
    }


    var addressShortCuts: [ShortCutButtonType] {
        [.icon("qr_scan_20"), .text("button.paste".localized)]
    }

    func onTapAddress(index: Int) {
        switch index {
        case 0: //qr_scan
            qrScanPresented = true
        case 1: //paste
            if let text = UIPasteboard.general.string?.replacingOccurrences(of: "\n", with: " ") {
                address = text
            }
        default: () //do_nothing
        }
    }

    var slippageShortCuts: [ShortCutButtonType] {
        MultiSwapSlippage.recommendedSlippages.map { $0.description + "%" }.map { .text($0) }
    }

    func slippage(at index: Int) -> Decimal {
        MultiSwapSlippage.recommendedSlippages.at(index: index) ??
                MultiSwapSlippage.recommendedSlippages[0]
    }

    func didFetch(_ string: String) {
        address = string
    }

    func onReset() {
        address = ""
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
