import UniswapKit
import EthereumKit
import RxCocoa
import RxSwift

class OneInchSettingsService {
    static let defaultSlippage: Decimal = 1
    var recommendedSlippages: [Decimal] = [0.1, 3]
    private var limitSlippageBounds: ClosedRange<Decimal> { 0.01...50 }
    private var usualHighestSlippage: Decimal = 5

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

    var recipient: Address? {
        didSet {
            sync()
        }
    }

    init(settings: OneInchSettings) {
        slippage = settings.allowedSlippage
        recipient = settings.recipient

        state = .valid(settings)
        sync()
    }

    private func sync() {
        var errors = [Error]()

        var settings = OneInchSettings()

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

        self.errors = errors

        state = errors.isEmpty ? .valid(settings) : .invalid
    }

}

extension OneInchSettingsService {

    var errorsObservable: Observable<[Error]> {
        errorsRelay.asObservable()
    }

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

}

extension OneInchSettingsService: IRecipientAddressService {

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

extension OneInchSettingsService: ISlippageService {

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
        Self.defaultSlippage
    }

    var initialSlippage: Decimal? {
        guard case let .valid(settings) = state, settings.allowedSlippage != Self.defaultSlippage else {
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

extension OneInchSettingsService {

    enum State {
        case valid(OneInchSettings)
        case invalid
    }

}
