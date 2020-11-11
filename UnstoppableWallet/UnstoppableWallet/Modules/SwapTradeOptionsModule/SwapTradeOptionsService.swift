import UniswapKit
import EthereumKit
import RxCocoa
import RxSwift

class SwapTradeOptionsService {
    var recommendedSlippageBounds: ClosedRange<Decimal> { 0.1...1 }
    private var limitSlippageBounds: ClosedRange<Decimal> { 0.01...20 }

    var recommendedDeadlineBounds: ClosedRange<TimeInterval> { 600...1800 }

    private var errorsRelay = BehaviorRelay<[Error]>(value: [])
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

        if slippage == .zero {
            errors.append(TradeOptionsError.zeroSlippage)
        } else if slippage > limitSlippageBounds.upperBound {
            errors.append(TradeOptionsError.invalidSlippage(.higher(max: limitSlippageBounds.upperBound)))
        } else if slippage < limitSlippageBounds.lowerBound {
            errors.append(TradeOptionsError.invalidSlippage(.lower(min: limitSlippageBounds.lowerBound)))
        } else {
            tradeOptions.allowedSlippage = slippage
        }

        if !deadline.isZero {
            tradeOptions.ttl = deadline
        } else {
            errors.append(TradeOptionsError.zeroDeadline)
        }

        if let recipient = recipient?.trimmingCharacters(in: .whitespaces), !recipient.isEmpty {
            do {
                tradeOptions.recipient = try Address(hex: recipient)
            } catch {
                errors.append(TradeOptionsError.invalidAddress)
            }
        }

        errorsRelay.accept(errors)
        state = errors.isEmpty ? .valid(tradeOptions) : .invalid
    }

}

extension SwapTradeOptionsService {

    public var errorsObservable: Observable<[Error]> {
        errorsRelay.asObservable()
    }

    public var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

}

extension SwapTradeOptionsService {

    enum InvalidSlippageType {
        case lower(min: Decimal)
        case higher(max: Decimal)
    }

    enum TradeOptionsError: Error {
        case zeroSlippage
        case zeroDeadline
        case invalidSlippage(InvalidSlippageType)
        case invalidAddress
    }

    enum State {
        case valid(TradeOptions)
        case invalid
    }

}
