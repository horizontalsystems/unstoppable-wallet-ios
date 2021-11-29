import Foundation
import UniswapKit
import EthereumKit
import RxCocoa
import RxSwift

class UniswapSettingsService {
    var recommendedSlippages: [Decimal] = [0.1, 1]
    private var limitSlippageBounds: ClosedRange<Decimal> { 0.01...50 }
    private var usualHighestSlippage: Decimal = 5

    var recommendedDeadlineBounds: ClosedRange<TimeInterval> { 600...1800 }

    private(set) var errors: [Error] = [] {
        didSet {
            errorsRelay.accept(errors)
        }
    }
    private let errorsRelay = PublishRelay<[Error]>()
    private let slippageChangeRelay = PublishRelay<Void>()

    private var stateRelay = BehaviorRelay<State>(value: .invalid)

    var state: State {
        didSet {
            stateRelay.accept(state)
        }
    }

    var slippage: Decimal {
        didSet {
            sync()
            slippageChangeRelay.accept(())
        }
    }

    var deadline: TimeInterval {
        didSet {
            sync()
        }
    }

    var recipient: Address? {
        didSet {
            sync()
        }
    }

    init(tradeOptions: UniswapSettings) {
        slippage = tradeOptions.allowedSlippage
        deadline = tradeOptions.ttl
        recipient = tradeOptions.recipient

        state = .valid(tradeOptions)
        sync()
    }

    private func sync() {
        var errors = [Error]()

        var settings = UniswapSettings()

        if let recipient = recipient, !recipient.raw.isEmpty {
            do {
                _ = try EthereumKit.Address(hex: recipient.raw)
                settings.recipient = recipient
            } catch {
                errors.append(SwapSettingsModule.AddressError.invalidAddress)
            }
        }

        if slippage == .zero {
            errors.append(SwapSettingsModule.SlippageError.zeroValue)
        } else if slippage > limitSlippageBounds.upperBound {
            errors.append(SwapSettingsModule.SlippageError.tooHigh(max: limitSlippageBounds.upperBound))
        } else if slippage < limitSlippageBounds.lowerBound {
            errors.append(SwapSettingsModule.SlippageError.tooLow(min: limitSlippageBounds.lowerBound))
        } else {
            settings.allowedSlippage = slippage
        }

        if !deadline.isZero {
            settings.ttl = deadline
        } else {
            errors.append(SwapSettingsModule.DeadlineError.zeroValue)
        }

        self.errors = errors

        state = errors.isEmpty ? .valid(settings) : .invalid
    }

}

extension UniswapSettingsService {

    var errorsObservable: Observable<[Error]> {
        errorsRelay.asObservable()
    }

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

}

extension UniswapSettingsService: IRecipientAddressService {

    var initialAddress: Address? {
        guard case let .valid(tradeOptions) = state else {
            return nil
        }

        return tradeOptions.recipient

    }

    var recipientError: Error? {
        errors.first { $0 is SwapSettingsModule.AddressError }
    }

    var recipientErrorObservable: Observable<Error?> {
        errorsRelay.map { errors -> Error? in
            errors.first { $0 is SwapSettingsModule.AddressError }
        }
    }

    func set(address: Address?) {
        recipient = address
    }

    func set(amount: Decimal) {
    }

}


extension UniswapSettingsService: ISlippageService {

    private func visibleSlippageError(errors: [Error]) -> Error? {
        errors.first {
            if let error = $0 as? SwapSettingsModule.SlippageError {
                switch error {
                case .zeroValue: return false
                default: return true
                }
            }
            return false
        }
    }

    var slippageError: Error? {
        visibleSlippageError(errors: errors)
    }

    var unusualSlippage: Bool {
        usualHighestSlippage < slippage
    }

    var defaultSlippage: Decimal {
        TradeOptions.defaultSlippage
    }

    var initialSlippage: Decimal? {
        guard case let .valid(settings) = state, settings.allowedSlippage != TradeOptions.defaultSlippage else {
            return nil
        }

        return settings.allowedSlippage
    }

    var slippageChangeObservable: Observable<Void> {
        slippageChangeRelay.asObservable()
    }

    func set(slippage: Decimal) {
        self.slippage = slippage
    }

}

extension UniswapSettingsService {

    enum State {
        case valid(UniswapSettings)
        case invalid
    }

}
