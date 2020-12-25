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

    var recipient: String? {
        didSet {
            sync()
        }
    }

    init(tradeOptions: TradeOptions) {
        slippage = tradeOptions.allowedSlippage
        deadline = tradeOptions.ttl
        recipient = tradeOptions.recipient?.hex

        state = .valid(tradeOptions)
        sync()
    }

    private func sync() {
        var errors = [Error]()

        var tradeOptions = TradeOptions()

        if let recipient = recipient?.trimmingCharacters(in: .whitespacesAndNewlines), !recipient.isEmpty {
            do {
                tradeOptions.recipient = try Address(hex: recipient)
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
        case valid(TradeOptions)
        case invalid
    }

}
