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
        }
    }

    init(oneInchProvider: OneInchProvider, state: SwapModuleNew.DataSourceState, evmKit: EthereumKit.Kit) {
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
    }

    private func syncQuote() {
        guard let coinIn = coinIn, let coinOut = coinOut else {
            state = .notReady(errors: [])
            return
        }

        quoteDisposeBag = DisposeBag()

        if quote == nil {
            state = .loading
        }

        oneInchProvider.quoteSingle(coinIn: coinIn, coinOut: coinOut, amount: amountIn)
                .subscribe(onSuccess: { [weak self] quote in
                    self?.quote = quote
                    self?.syncSwapTransaction()
                }, onError: { [weak self] error in
                    self?.state = .notReady(errors: [error])
                })
                .disposed(by: quoteDisposeBag)
    }

    private func syncSwapTransaction() {
//        guard let swapData = swapData else {
//            return false
//        }
//
//        let amount = tradeType == .exactIn ? amountIn : amountOut
//
//        guard amount > 0 else {
//            state = .notReady(errors: [])
//            return false
//        }
//
//        do {
//            let tradeData = try uniswapProvider.tradeData(swapData: swapData, amount: amount, tradeType: tradeType, tradeOptions: swapTradeOptions.tradeOptions)
//            handle(tradeData: tradeData)
//            return true
//        } catch {
//            state = .notReady(errors: [error])
//            return false
//        }
    }

//    private func handle(tradeData: TradeData) {
//        let estimatedAmount = tradeData.type == .exactIn ? tradeData.amountOut : tradeData.amountIn
//
//        switch tradeData.type {
//        case .exactIn:
//            amountOut = estimatedAmount ?? 0
//        case .exactOut:
//            amountIn = estimatedAmount ?? 0
//        }
//
//        let trade = Trade(tradeData: tradeData)
//        state = .ready(trade: trade)
//    }

    deinit {
        print("Deinit \(self)")
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

//    var swapTradeOptionsObservable: Observable<SwapTradeOptions> {
//        swapTradeOptionsRelay.asObservable()
//    }

//    func transactionData(tradeData: TradeData) throws -> TransactionData {
//        try uniswapProvider.transactionData(tradeData: tradeData)
//    }

    func set(coinIn: Coin?) {
//        guard self.coinIn != coinIn else {
//            return
//        }
//
//        self.coinIn = coinIn
//        if tradeType == .exactOut {
//            amountIn = 0
//        }
//
//        if coinOut == coinIn {
//            coinOut = nil
//            amountOut = 0
//        }
//
//        swapData = nil
//        syncQuote()
    }

    func set(coinOut: Coin?) {
//        guard self.coinOut != coinOut else {
//            return
//        }
//
//        self.coinOut = coinOut
//        if tradeType == .exactIn {
//            amountOut = 0
//        }
//
//        if coinIn == coinOut {
//            coinIn = nil
//            amountIn = 0
//        }
//
//        swapData = nil
//        syncQuote()
    }

    func set(amountIn: Decimal) {
//        guard self.amountIn != amountIn else {
//            return
//        }
//
//        tradeType = .exactIn
//
//        self.amountIn = amountIn
//
//        if !syncSwapTransaction() {
//            amountOut = 0
//        }
    }

    func set(amountOut: Decimal) {
//        guard self.amountOut != amountOut else {
//            return
//        }
//
//        tradeType = .exactOut
//
//        self.amountOut = amountOut
//
//        if !syncSwapTransaction() {
//            amountIn = 0
//        }
    }

    func switchCoins() {
//        let swapCoin = coinOut
//        coinOut = coinIn
//
//        set(coinIn: swapCoin)
    }

}

extension OneInchTradeService {

    enum State {
        case loading
        case ready
        case notReady(errors: [Error])
    }

}
