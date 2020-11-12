import Foundation
import EthereumKit
import UniswapKit
import RxSwift
import RxRelay

class SwapTradeService {
    private static let warningPriceImpact: Decimal = 1
    private static let forbiddenPriceImpact: Decimal = 5

    private let uniswapRepository: UniswapRepository

    private var disposeBag = DisposeBag()

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

    private let tradeOptionsRelay = PublishRelay<TradeOptions>()
    var tradeOptions = TradeOptions() {
        didSet {
            tradeOptionsRelay.accept(tradeOptions)
        }
    }

    init(uniswapRepository: UniswapRepository, coin: Coin? = nil) {
        self.uniswapRepository = uniswapRepository
        coinIn = coin
    }

    private func syncState() {
        guard let coinIn = coinIn, let coinOut = coinOut, let amount = tradeType == .exactIn ? amountIn : amountOut else {
            state = .notReady(errors: [])
            return
        }

        disposeBag = DisposeBag()

        state = .loading

        uniswapRepository
                .trade(coinIn: coinIn, coinOut: coinOut, amount: amount, tradeType: tradeType, tradeOptions: tradeOptions)
                .subscribe(onSuccess: { [weak self] tradeData in
                    self?.handle(tradeData: tradeData)
                }, onError: { [weak self] error in
                    self?.state = .notReady(errors: [error])
                })
                .disposed(by: disposeBag)
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

    var tradeOptionsObservable: Observable<TradeOptions> {
        tradeOptionsRelay.asObservable()
    }

    func transactionData(tradeData: TradeData) throws -> TransactionData {
        try uniswapRepository.transactionData(tradeData: tradeData)
    }

    func set(coinIn: Coin?) {
        guard self.coinIn != coinIn else {
            return
        }

        self.coinIn = coinIn

        if coinOut == coinIn {
            coinOut = nil
        }

//        amountOut = nil

        syncState()
    }

    func set(coinOut: Coin?) {
        guard self.coinOut != coinOut else {
            return
        }

        self.coinOut = coinOut

        if coinIn == coinOut {
            coinIn = nil
        }

//        amountIn = nil

        syncState()
    }

    func set(amountIn: Decimal?) {
        tradeType = .exactIn

        guard self.amountIn != amountIn else {
            return
        }

        self.amountIn = amountIn
        amountOut = nil

        syncState()
    }

    func set(amountOut: Decimal?) {
        tradeType = .exactOut

        guard self.amountOut != amountOut else {
            return
        }

        self.amountOut = amountOut
        amountIn = nil

        syncState()
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
        case none
        case normal
        case warning
        case forbidden
    }

    struct Trade {
        let tradeData: TradeData
        let impactLevel: PriceImpactLevel

        init(tradeData: TradeData) {
            self.tradeData = tradeData

            if let priceImpact = tradeData.priceImpact {
                switch priceImpact {
                case 0..<SwapTradeService.warningPriceImpact: impactLevel = .normal
                case SwapTradeService.warningPriceImpact..<SwapTradeService.forbiddenPriceImpact: impactLevel = .warning
                default: impactLevel = .forbidden
                }
            } else {
                impactLevel = .none
            }
        }

        var minMaxAmount: Decimal? {
            tradeData.type == .exactIn ? tradeData.amountOutMin : tradeData.amountInMax
        }

    }

}
