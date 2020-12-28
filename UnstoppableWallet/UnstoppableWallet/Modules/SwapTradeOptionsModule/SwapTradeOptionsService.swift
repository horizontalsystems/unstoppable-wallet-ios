import UniswapKit
import EthereumKit
import RxCocoa
import RxSwift

class SwapTradeOptionsService {
    var recommendedSlippageBounds: ClosedRange<Decimal> { 0.1...1 }
    private var limitSlippageBounds: ClosedRange<Decimal> { 0.01...20 }

    var recommendedDeadlineBounds: ClosedRange<TimeInterval> { 600...1800 }

    private(set) var errors: [Error] = [] {
        didSet {
            errorsRelay.accept(errors)
        }
    }
    private let errorsRelay = PublishRelay<[Error]>()

    private var stateRelay = BehaviorRelay<State>(value: .invalid)

    var state: State {
        didSet {
            stateRelay.accept(state)
        }
    }

    var slippage: Decimal {
        didSet {
            sync()
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

    init(tradeOptions: SwapTradeOptions) {
        slippage = tradeOptions.allowedSlippage
        deadline = tradeOptions.ttl
        recipient = tradeOptions.recipient

        state = .valid(tradeOptions)
        sync()
    }

    private func sync() {
        var errors = [Error]()

        var tradeOptions = SwapTradeOptions()

        if let recipient = recipient, !recipient.raw.isEmpty {
            do {
                _ = try EthereumKit.Address(hex: recipient.raw)
                tradeOptions.recipient = recipient
            } catch {
                errors.append(AddressError.invalidAddress)
            }
        }

        if slippage == .zero {
            errors.append(SlippageError.zeroValue)
        } else if slippage > limitSlippageBounds.upperBound {
            errors.append(SlippageError.tooHigh(max: limitSlippageBounds.upperBound))
        } else if slippage < limitSlippageBounds.lowerBound {
            errors.append(SlippageError.tooLow(min: limitSlippageBounds.lowerBound))
        } else {
            tradeOptions.allowedSlippage = slippage
        }

        if !deadline.isZero {
            tradeOptions.ttl = deadline
        } else {
            errors.append(DeadlineError.zeroValue)
        }

        self.errors = errors

        state = errors.isEmpty ? .valid(tradeOptions) : .invalid
    }

}

extension SwapTradeOptionsService {

    var errorsObservable: Observable<[Error]> {
        errorsRelay.asObservable()
    }

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

}

extension SwapTradeOptionsService: IRecipientAddressService {

    var initialAddress: Address? {
        guard case let .valid(tradeOptions) = state else {
            return nil
        }

        return tradeOptions.recipient

    }

    var error: Error? {
        errors.first { $0 is SwapTradeOptionsService.AddressError }
    }

    var errorObservable: Observable<Error?> {
        errorsRelay.map { errors -> Error? in
            errors.first { $0 is SwapTradeOptionsService.AddressError }
        }
    }

    func set(address: Address?) {
        recipient = address
    }

    func set(amount: Decimal) {
    }

}

extension SwapTradeOptionsService {

    enum AddressError: Error {
        case invalidAddress
    }

    enum SlippageError: Error {
        case zeroValue
        case tooLow(min: Decimal)
        case tooHigh(max: Decimal)
    }

    enum DeadlineError: Error {
        case zeroValue
    }

    enum State {
        case valid(SwapTradeOptions)
        case invalid
    }

}
