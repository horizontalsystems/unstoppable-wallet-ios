import Foundation
import EthereumKit
import OneInchKit
import RxSwift
import RxRelay
import MarketKit

class OneInchTradeService {
    private var disposeBag = DisposeBag()
    private var quoteDisposeBag = DisposeBag()

    private let oneInchProvider: OneInchProvider
    private var quote: OneInchKit.Quote?

    private(set) var platformCoinIn: PlatformCoin? {
        didSet {
            if platformCoinIn != oldValue {
                platformCoinInRelay.accept(platformCoinIn)
            }
        }
    }

    private(set) var platformCoinOut: PlatformCoin? {
        didSet {
            if platformCoinOut != oldValue {
                platformCoinOutRelay.accept(platformCoinOut)
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

    private var platformCoinInRelay = PublishRelay<PlatformCoin?>()
    private var platformCoinOutRelay = PublishRelay<PlatformCoin?>()

    private var amountInRelay = PublishRelay<Decimal>()
    private var amountOutRelay = PublishRelay<Decimal>()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .notReady(errors: []) {
        didSet {
            stateRelay.accept(state)
        }
    }

    private let settingsRelay = PublishRelay<OneInchSettings>()
    var settings = OneInchSettings() {
        didSet {
            settingsRelay.accept(settings)
            syncQuote()
        }
    }

    init(oneInchProvider: OneInchProvider, state: SwapModule.DataSourceState, evmKit: EthereumKit.Kit) {
        self.oneInchProvider = oneInchProvider
        platformCoinIn = state.platformCoinFrom
        platformCoinOut = state.platformCoinTo
        amountIn = state.amountFrom ?? 0

        evmKit.lastBlockHeightObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] blockNumber in
                    self?.syncQuote()
                })
                .disposed(by: disposeBag)

        syncQuote()
    }

    @discardableResult private func syncQuote() -> Bool {
        guard let platformCoinIn = platformCoinIn, let platformCoinOut = platformCoinOut else {
            state = .notReady(errors: [])
            return false
        }

        quoteDisposeBag = DisposeBag()

//        if quote == nil {
        state = .loading
//        }

        let amountIn = amountIn
        guard amountIn > 0 else {
            state = .notReady(errors: [])
            return false
        }

        oneInchProvider.quoteSingle(platformCoinIn: platformCoinIn, platformCoinOut: platformCoinOut, amount: amountIn)
                .subscribe(onSuccess: { [weak self] quote in
                    self?.handle(quote: quote, platformCoinFrom: platformCoinIn, platformCoinTo: platformCoinOut, amountFrom: amountIn)
                }, onError: { [weak self] error in
                    self?.state = .notReady(errors: [error.convertedError])
                })
                .disposed(by: quoteDisposeBag)

        return true
    }

    private func handle(quote: OneInchKit.Quote, platformCoinFrom: PlatformCoin, platformCoinTo: PlatformCoin, amountFrom: Decimal) {
        self.quote = quote

        amountOut = quote.amountOut ?? 0

        let parameters = OneInchSwapParameters(
            platformCoinFrom: platformCoinFrom,
            platformCoinTo: platformCoinTo,
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

    var platformCoinInObservable: Observable<PlatformCoin?> {
        platformCoinInRelay.asObservable()
    }

    var platformCoinOutObservable: Observable<PlatformCoin?> {
        platformCoinOutRelay.asObservable()
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

    func set(platformCoinIn: PlatformCoin?) {
        guard self.platformCoinIn != platformCoinIn else {
            return
        }

        self.platformCoinIn = platformCoinIn
        amountIn = 0
        amountOut = 0
        if platformCoinOut == platformCoinIn {
            platformCoinOut = nil
        }

        quote = nil
        syncQuote()
    }

    func set(platformCoinOut: PlatformCoin?) {
        guard self.platformCoinOut != platformCoinOut else {
            return
        }

        self.platformCoinOut = platformCoinOut
        amountOut = 0

        if platformCoinIn == platformCoinOut {
            platformCoinIn = nil
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
        let swapPlatformCoin = platformCoinOut
        platformCoinOut = platformCoinIn

        set(platformCoinIn: swapPlatformCoin)
    }

}

extension OneInchTradeService {

    enum State {
        case loading
        case ready(parameters: OneInchSwapParameters)
        case notReady(errors: [Error])
    }

}
