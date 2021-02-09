import Foundation
import EthereumKit
import UniswapKit
import RxSwift
import RxRelay

class SwapTradeService {
    private var disposeBag = DisposeBag()
    private static let warningPriceImpact: Decimal = 1
    private static let forbiddenPriceImpact: Decimal = 5

    private let uniswapProvider: UniswapProvider

    private var swapDataDisposeBag = DisposeBag()

    private var swapData: SwapData?

    private(set) var coinIn: Coin? {
        didSet {
            coinInRelay.accept(coinIn)
        }
    }

    private(set) var coinOut: Coin? {
        didSet {
            coinOutRelay.accept(coinOut)
        }
    }

    private(set) var amountIn: Decimal? {
        didSet {
            amountInRelay.accept(amountIn)
        }
    }

    private(set) var amountOut: Decimal? {
        didSet {
            amountOutRelay.accept(amountOut)
        }
    }

    private(set) var tradeType: TradeType = .exactIn {
        didSet {
            tradeTypeRelay.accept(tradeType)
        }
    }

    private var tradeTypeRelay = PublishRelay<TradeType>()
    private var coinInRelay = PublishRelay<Coin?>()
    private var coinOutRelay = PublishRelay<Coin?>()

    private var amountInRelay = PublishRelay<Decimal?>()
    private var amountOutRelay = PublishRelay<Decimal?>()

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
            syncTradeData()
        }
    }

    init(uniswapProvider: UniswapProvider, coin: Coin? = nil, ethereumKit: EthereumKit.Kit) {
        self.uniswapProvider = uniswapProvider
        coinIn = coin

        ethereumKit.lastBlockHeightObservable
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
                    self?.syncTradeData()
                }, onError: { [weak self] error in
                    self?.state = .notReady(errors: [error])
                })
                .disposed(by: swapDataDisposeBag)
    }

    private func syncTradeData() {
        guard let swapData = swapData else {
            return
        }

        guard let amount = tradeType == .exactIn ? amountIn : amountOut else {
            state = .notReady(errors: [])
            return
        }

        do {
            let tradeData = try uniswapProvider.tradeData(swapData: swapData, amount: amount, tradeType: tradeType, tradeOptions: swapTradeOptions.tradeOptions)
            handle(tradeData: tradeData)
        } catch {
            state = .notReady(errors: [error])
        }
    }

    private func handle(tradeData: TradeData) {
        let estimatedAmount = tradeData.type == .exactIn ? tradeData.amountOut : tradeData.amountIn

        switch tradeData.type {
        case .exactIn:
            amountOut = estimatedAmount
        case .exactOut:
            amountIn = estimatedAmount
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

    var amountInObservable: Observable<Decimal?> {
        amountInRelay.asObservable()
    }

    var amountOutObservable: Observable<Decimal?> {
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
            amountIn = nil
        }

        if coinOut == coinIn {
            coinOut = nil
            amountOut = nil
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
            amountOut = nil
        }

        if coinIn == coinOut {
            coinIn = nil
            amountIn = nil
        }

        swapData = nil
        syncSwapData()
    }

    func set(amountIn: Decimal?) {
        tradeType = .exactIn

        guard self.amountIn != amountIn else {
            return
        }

        self.amountIn = amountIn
        amountOut = nil

        syncTradeData()
    }

    func set(amountOut: Decimal?) {
        tradeType = .exactOut

        guard self.amountOut != amountOut else {
            return
        }

        self.amountOut = amountOut
        amountIn = nil

        syncTradeData()
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
