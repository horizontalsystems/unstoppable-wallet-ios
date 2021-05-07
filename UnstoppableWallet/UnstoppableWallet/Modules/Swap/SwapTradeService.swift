import Foundation
import EthereumKit
import UniswapKit
import RxSwift
import RxRelay
import CoinKit

class SwapTradeService {
    private var disposeBag = DisposeBag()
    private static let warningPriceImpact: Decimal = 1
    private static let forbiddenPriceImpact: Decimal = 5

    private let uniswapProvider: UniswapProvider

    private var swapDataDisposeBag = DisposeBag()

    private var swapData: SwapData?

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

    private(set) var tradeType: TradeType = .exactIn {
        didSet {
            if tradeType != oldValue {
                tradeTypeRelay.accept(tradeType)
            }
        }
    }

    private var tradeTypeRelay = PublishRelay<TradeType>()
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

    private let swapTradeOptionsRelay = PublishRelay<SwapTradeOptions>()
    var swapTradeOptions = SwapTradeOptions() {
        didSet {
            swapTradeOptionsRelay.accept(swapTradeOptions)
            _ = syncTradeData()
        }
    }

    init(uniswapProvider: UniswapProvider, coin: Coin? = nil, evmKit: EthereumKit.Kit) {
        self.uniswapProvider = uniswapProvider
        coinIn = coin

        evmKit.lastBlockHeightObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] blockNumber in
                    self?.syncSwapData()
                })
                .disposed(by: disposeBag)
    }

    private func syncSwapData() {
        guard let coinIn = coinIn, let coinOut = coinOut else {
            state = .notReady(errors: [])
            return
        }

        swapDataDisposeBag = DisposeBag()

        if swapData == nil {
            state = .loading
        }

        uniswapProvider
                .swapDataSingle(coinIn: coinIn, coinOut: coinOut)
                .subscribe(onSuccess: { [weak self] swapData in
                    self?.swapData = swapData
                    _ = self?.syncTradeData()
                }, onError: { [weak self] error in
                    self?.state = .notReady(errors: [error])
                })
                .disposed(by: swapDataDisposeBag)
    }

    private func syncTradeData() -> Bool {
        guard let swapData = swapData else {
            return false
        }

        let amount = tradeType == .exactIn ? amountIn : amountOut

        guard amount > 0 else {
            state = .notReady(errors: [])
            return false
        }

        do {
            let tradeData = try uniswapProvider.tradeData(swapData: swapData, amount: amount, tradeType: tradeType, tradeOptions: swapTradeOptions.tradeOptions)
            handle(tradeData: tradeData)
            return true
        } catch {
            state = .notReady(errors: [error])
            return false
        }
    }

    private func handle(tradeData: TradeData) {
        let estimatedAmount = tradeData.type == .exactIn ? tradeData.amountOut : tradeData.amountIn

        switch tradeData.type {
        case .exactIn:
            amountOut = estimatedAmount ?? 0
        case .exactOut:
            amountIn = estimatedAmount ?? 0
        }

        let trade = Trade(tradeData: tradeData)
        state = .ready(trade: trade)
    }

}

extension SwapTradeService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var tradeTypeObservable: Observable<TradeType> {
        tradeTypeRelay.asObservable()
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

    var swapTradeOptionsObservable: Observable<SwapTradeOptions> {
        swapTradeOptionsRelay.asObservable()
    }

    func transactionData(tradeData: TradeData) throws -> TransactionData {
        try uniswapProvider.transactionData(tradeData: tradeData)
    }

    func set(coinIn: Coin?) {
        guard self.coinIn != coinIn else {
            return
        }

        self.coinIn = coinIn
        if tradeType == .exactOut {
            amountIn = 0
        }

        if coinOut == coinIn {
            coinOut = nil
            amountOut = 0
        }

        swapData = nil
        syncSwapData()
    }

    func set(coinOut: Coin?) {
        guard self.coinOut != coinOut else {
            return
        }

        self.coinOut = coinOut
        if tradeType == .exactIn {
            amountOut = 0
        }

        if coinIn == coinOut {
            coinIn = nil
            amountIn = 0
        }

        swapData = nil
        syncSwapData()
    }

    func set(amountIn: Decimal) {
        guard self.amountIn != amountIn else {
            return
        }

        tradeType = .exactIn

        self.amountIn = amountIn

        if !syncTradeData() {
            amountOut = 0
        }
    }

    func set(amountOut: Decimal) {
        guard self.amountOut != amountOut else {
            return
        }

        tradeType = .exactOut

        self.amountOut = amountOut

        if !syncTradeData() {
            amountIn = 0
        }
    }

    func switchCoins() {
        let swapCoin = coinOut
        coinOut = coinIn

        set(coinIn: swapCoin)
    }

}

extension SwapTradeService {

    enum State {
        case loading
        case ready(trade: Trade)
        case notReady(errors: [Error])
    }

    enum PriceImpactLevel: Int {
        case normal
        case warning
        case forbidden
    }

    struct Trade {
        let tradeData: TradeData
        let impactLevel: PriceImpactLevel?

        init(tradeData: TradeData) {
            self.tradeData = tradeData

            impactLevel = tradeData.priceImpact.map { priceImpact in
                switch priceImpact {
                case 0..<SwapTradeService.warningPriceImpact: return .normal
                case SwapTradeService.warningPriceImpact..<SwapTradeService.forbiddenPriceImpact: return .warning
                default: return .forbidden
                }
            }
        }
    }

}
