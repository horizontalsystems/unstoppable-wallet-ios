import UniswapKit
import EthereumKit
import RxCocoa
import RxSwift

class OneInchSettingsService {
    static let defaultSlippage: Decimal = 1
    var recommendedSlippages: [Decimal] = [0.1, 3]
    private var limitSlippageBounds: ClosedRange<Decimal> { 0.01...50 }
    private var usualHighestSlippage: Decimal = 5

    private let disposeBag = DisposeBag()
    private let addressParserChain: AddressParserChain

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

    init(settings: OneInchSettings, addressParserChain: AddressParserChain) {
        self.addressParserChain = addressParserChain
        slippage = settings.allowedSlippage

        state = .valid(settings)

        subscribe(disposeBag, addressParserChain.stateObservable) { [weak self] _ in self?.sync() }
        sync()
    }

    private func sync() {
        var errors = [Error]()
        var loading = false

        var settings = OneInchSettings()

        switch addressParserChain.state {
        case .loading: loading = true
        case .success(let address): settings.recipient = address
        case .validationError(_): errors.append(SwapSettingsModule.AddressError.invalidAddress)
        case .fetchError(_): errors.append(SwapSettingsModule.AddressError.invalidAddress)
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

        self.errors = errors

        state = (!errors.isEmpty || loading) ? .invalid : .valid(settings)
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

    var addressState: AddressParserChain.State {
        addressParserChain.state
    }

    var addressStateObservable: Observable<AddressParserChain.State> {
        addressParserChain.stateObservable
    }

    func set(address: String?) {
        addressParserChain.handle(address: address)
    }

    var recipientError: Error? {
        errors.first { $0 is SwapSettingsModule.AddressError }
    }

    var recipientErrorObservable: Observable<Error?> {
        errorsRelay.map { errors -> Error? in
            errors.first { $0 is SwapSettingsModule.AddressError }
        }
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
