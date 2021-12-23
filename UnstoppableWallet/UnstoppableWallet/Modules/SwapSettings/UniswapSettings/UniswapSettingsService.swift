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

    private let disposeBag = DisposeBag()
    private let addressService: AddressService

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

    init(tradeOptions: UniswapSettings, addressService: AddressService) {
        self.addressService = addressService
        slippage = tradeOptions.allowedSlippage
        deadline = tradeOptions.ttl

        state = .valid(tradeOptions)

        subscribe(disposeBag, addressService.stateObservable) { [weak self] _ in self?.sync() }
        sync()
    }

    private func sync() {
        var errors = [Error]()
        var loading = false

        var settings = UniswapSettings()

        switch addressService.state {
        case .loading: loading = true
        case .success(let address): settings.recipient = address
        case .validationError: errors.append(SwapSettingsModule.AddressError.invalidAddress)
        case .fetchError: errors.append(SwapSettingsModule.AddressError.invalidAddress)
        default: ()
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

        state = (!errors.isEmpty || loading) ? .invalid : .valid(settings)
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
