import UniswapKit
import EthereumKit
import RxCocoa
import RxSwift

enum InvalidSlippageType {
    case lower
    case higher
}
enum SwapTradeOptionsError: Error {
    case invalidSlippage(InvalidSlippageType)
    case invalidAddress
}

enum SwapTradeOptionsState {
    case valid(TradeOptions)
    case invalid
}

extension SwapTradeOptionsError: LocalizedError {

    var errorDescription: String? {
        switch self {
        case .invalidSlippage(let type): return type == .lower ? "swap.advanced_settings.error.lower_slippage".localized : "swap.advanced_settings.error.higher_slippage".localized
        case .invalidAddress: return "send.error.invalid_address".localized
        }
    }

}

class SwapTradeOptionsService {
    var defaultSlippage: Decimal { 0.5 }
    var recommendedSlippageBounds: ClosedRange<Decimal> { 0.1...1 }
    private var limitSlippageBounds: ClosedRange<Decimal> { 0.01...20 }

    var defaultDeadline: TimeInterval { 20 }
    var recommendedDeadlineBounds: ClosedRange<TimeInterval> { 10...30 }

    private var errorsRelay = BehaviorRelay<[Error]>(value: [])
    private var stateRelay = BehaviorRelay<SwapTradeOptionsState>(value: .invalid)

    var state: SwapTradeOptionsState {
        didSet {
            stateRelay.accept(state)
        }
    }

    var slippage: Decimal? {
        didSet {
            sync()
        }
    }

    var deadline: TimeInterval? {
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
        var correct = true

        if let slippage = slippage {
            print("slippage = \(slippage.description)")
            if !limitSlippageBounds.contains(slippage) && !slippage.isZero {
                correct = false
                let error: SwapTradeOptionsError = slippage < limitSlippageBounds.lowerBound ? .invalidSlippage(.lower) : .invalidSlippage(.higher)
                errors.append(error)
            } else {
                tradeOptions.allowedSlippage = slippage
            }
        } else {
            print("slippage = N/A")
        }

        if let deadline = deadline {
            print("deadline = \(deadline.description)")
            if deadline.isZero {
                correct = false
            } else {
                tradeOptions.ttl = deadline
            }
        } else {
            print("deadline = N/A")
        }

        if let recipient = recipient {
            print("recipient = \(recipient.description)")
            if !recipient.isEmpty {
                do {
                    tradeOptions.recipient = try Address(hex: recipient)
                } catch {
                    correct = false
                    errors.append(SwapTradeOptionsError.invalidAddress)
                }
            }
        } else {
            print("recipient = N/A")
        }

        errorsRelay.accept(errors)
        stateRelay.accept(correct ? .valid(tradeOptions) : .invalid)
    }

}

extension SwapTradeOptionsService {

    public var errorsObservable: Observable<[Error]> {
        errorsRelay.asObservable()
    }

    public var stateObservable: Observable<SwapTradeOptionsState> {
        stateRelay.asObservable()
    }

}
