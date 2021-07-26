import Foundation
import EthereumKit
import OneInchKit
import RxSwift
import RxRelay
import CoinKit

class OneInchTradeService {
    private var disposeBag = DisposeBag()
    private var quoteDisposeBag = DisposeBag()

    private let oneInchProvider: OneInchProvider
    private var quote: OneInchKit.Quote?

    private(set) var coinIn: Coin? {
        didSet {
            if coinIn != oldValue {
                coinInRelay.accept(coinIn)
            }
        }
    }

    private(set) var coinOut: Coin? {
        didSet {
            if coinOut != oldValue {
                coinOutRelay.accept(coinOut)
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

    private var coinInRelay = PublishRelay<Coin?>()
    private var coinOutRelay = PublishRelay<Coin?>()

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
        coinIn = state.coinFrom
        coinOut = state.coinTo
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
        guard let coinIn = coinIn, let coinOut = coinOut else {
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

        oneInchProvider.quoteSingle(coinIn: coinIn, coinOut: coinOut, amount: amountIn)
                .subscribe(onSuccess: { [weak self] quote in
                    self?.handle(quote: quote, coinFrom: coinIn, coinTo: coinOut, amountFrom: amountIn)
                }, onError: { [weak self] error in
                    self?.state = .notReady(errors: [error])
                })
                .disposed(by: quoteDisposeBag)

        return true
    }

    private func handle(quote: OneInchKit.Quote, coinFrom: Coin, coinTo: Coin, amountFrom: Decimal) {
        self.quote = quote

        amountOut = quote.amountOut ?? 0

        let parameters = OneInchSwapParameters(
            coinFrom: coinFrom,
            coinTo: coinTo,
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

    var coinInObservable: Observable<Coin?> {
        coinInRelay.asObservable()
    }

    var coinOutObservable: Observable<Coin?> {
        coinOutRelay.asObservable()
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

    func set(coinIn: Coin?) {
        guard self.coinIn != coinIn else {
            return
        }

        self.coinIn = coinIn
        amountIn = 0
        amountOut = 0
        if coinOut == coinIn {
            coinOut = nil
        }

        quote = nil
        syncQuote()
    }

    func set(coinOut: Coin?) {
        guard self.coinOut != coinOut else {
            return
        }

        self.coinOut = coinOut
        amountOut = 0

        if coinIn == coinOut {
            coinIn = nil
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
        let swapCoin = coinOut
        coinOut = coinIn

        set(coinIn: swapCoin)
    }

}

extension OneInchTradeService {

    enum State {
        case loading
        case ready(parameters: OneInchSwapParameters)
        case notReady(errors: [Error])
    }

}
