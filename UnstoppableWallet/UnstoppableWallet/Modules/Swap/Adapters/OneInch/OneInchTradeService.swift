import Foundation
import EvmKit
import OneInchKit
import RxSwift
import RxRelay
import MarketKit

class OneInchTradeService {
    private static let timerFramePerSecond = 30

    private let disposeBag = DisposeBag()
    private var refreshTimerDisposeBag = DisposeBag()
    private var quoteDisposeBag = DisposeBag()

    private let oneInchProvider: OneInchProvider
    let syncInterval: TimeInterval

    private var quote: OneInchKit.Quote?

    private(set) var tokenIn: MarketKit.Token? {
        didSet {
            if tokenIn != oldValue {
                tokenInRelay.accept(tokenIn)
            }
        }
    }

    private(set) var tokenOut: MarketKit.Token? {
        didSet {
            if tokenOut != oldValue {
                tokenOutRelay.accept(tokenOut)
            }
        }
    }

    private(set) var amountIn: Decimal = 0 {
        didSet {
            if amountIn != oldValue {
                amountInRelay.accept(amountIn)
            }
        }
    }

    private(set) var amountOut: Decimal = 0 {
        didSet {
            if amountOut != oldValue {
                amountOutRelay.accept(amountOut)
            }
        }
    }

    private var tokenInRelay = PublishRelay<MarketKit.Token?>()
    private var tokenOutRelay = PublishRelay<MarketKit.Token?>()

    private var amountInRelay = PublishRelay<Decimal>()
    private var amountOutRelay = PublishRelay<Decimal>()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .notReady(errors: []) {
        didSet {
            stateRelay.accept(state)
        }
    }

    private let countdownTimerRelay = PublishRelay<Float>()

    private let settingsRelay = PublishRelay<OneInchSettings>()
    var settings = OneInchSettings() {
        didSet {
            settingsRelay.accept(settings)
            syncQuote()
        }
    }

    init(oneInchProvider: OneInchProvider, state: SwapModule.DataSourceState, evmKit: EvmKit.Kit) {
        self.oneInchProvider = oneInchProvider
        syncInterval = evmKit.chain.syncInterval

        tokenIn = state.tokenFrom
        tokenOut = state.tokenTo
        amountIn = state.amountFrom ?? 0

        evmKit.lastBlockHeightObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] blockNumber in
                    self?.syncQuote()
                })
                .disposed(by: disposeBag)

        syncQuote()
    }

    private func syncTimer() {
        refreshTimerDisposeBag = DisposeBag()
        let countdownValue = Int(syncInterval) * Self.timerFramePerSecond

        Observable<Int>
                .interval(.milliseconds(1000 / Self.timerFramePerSecond), scheduler: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .map {
                    countdownValue - $0
                }
                .takeUntil(.inclusive, predicate: { $0 == 0 })
                .subscribe(onNext: { [weak self] value in
                    self?.countdownTimerRelay.accept(Float(value) / Float(countdownValue))
                }, onCompleted: { [weak self] in
                    self?.syncQuote()
                })
                .disposed(by: refreshTimerDisposeBag)
    }

    @discardableResult private func syncQuote() -> Bool {
        guard let tokenIn = tokenIn, let tokenOut = tokenOut else {
            state = .notReady(errors: [])
            return false
        }

        quoteDisposeBag = DisposeBag()
        syncTimer()
//        if quote == nil {
        state = .loading
//        }

        let amountIn = amountIn
        guard amountIn > 0 else {
            state = .notReady(errors: [])
            return false
        }

        oneInchProvider.quoteSingle(tokenIn: tokenIn, tokenOut: tokenOut, amount: amountIn)
                .subscribe(onSuccess: { [weak self] quote in
                    self?.handle(quote: quote, tokenFrom: tokenIn, tokenTo: tokenOut, amountFrom: amountIn)
                }, onError: { [weak self] error in
                    var identifiedError = error.convertedError

                    if let error = identifiedError as? AppError,
                        case .invalidResponse(let reason) = error {

                        if reason.contains("liquidity") {
                            identifiedError = AppError.oneInch(reason: .insufficientLiquidity)
                        }
                    }

                    self?.state = .notReady(errors: [identifiedError])
                })
                .disposed(by: quoteDisposeBag)

        return true
    }

    private func handle(quote: OneInchKit.Quote, tokenFrom: MarketKit.Token, tokenTo: MarketKit.Token, amountFrom: Decimal) {
        self.quote = quote

        amountOut = quote.amountOut ?? 0

        let parameters = OneInchSwapParameters(
            tokenFrom: tokenFrom,
            tokenTo: tokenTo,
            amountFrom: amountFrom,
            amountTo: amountOut,
            slippage: settings.allowedSlippage,
            recipient: settings.recipient
        )

        state = .ready(parameters: parameters)
    }

}

extension OneInchTradeService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var countdownTimerObservable: Observable<Float> {
        countdownTimerRelay.asObservable()
    }

    var tokenInObservable: Observable<MarketKit.Token?> {
        tokenInRelay.asObservable()
    }

    var tokenOutObservable: Observable<MarketKit.Token?> {
        tokenOutRelay.asObservable()
    }

    var amountInObservable: Observable<Decimal> {
        amountInRelay.asObservable()
    }

    var amountOutObservable: Observable<Decimal> {
        amountOutRelay.asObservable()
    }

    var settingsObservable: Observable<OneInchSettings> {
        settingsRelay.asObservable()
    }

    func set(tokenIn: MarketKit.Token?) {
        guard self.tokenIn != tokenIn else {
            return
        }

        self.tokenIn = tokenIn
        amountIn = 0
        amountOut = 0
        if tokenOut == tokenIn {
            tokenOut = nil
        }

        quote = nil
        syncQuote()
    }

    func set(tokenOut: MarketKit.Token?) {
        guard self.tokenOut != tokenOut else {
            return
        }

        self.tokenOut = tokenOut
        amountOut = 0

        if tokenIn == tokenOut {
            tokenIn = nil
            amountIn = 0
        }

        quote = nil
        syncQuote()
    }

    func set(amountIn: Decimal) {
        guard self.amountIn != amountIn else {
            return
        }
        self.amountIn = amountIn

        if !syncQuote() {
            amountOut = 0
        }
    }

    func switchCoins() {
        let swapToken = tokenOut
        tokenOut = tokenIn

        set(tokenIn: swapToken)
    }

}

extension OneInchTradeService {

    enum State {
        case loading
        case ready(parameters: OneInchSwapParameters)
        case notReady(errors: [Error])
    }

}
