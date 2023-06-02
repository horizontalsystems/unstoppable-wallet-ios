import Foundation
import EvmKit
import UniswapKit
import RxSwift
import RxRelay
import MarketKit
import HsExtensions

class UniswapTradeService: ISwapSettingProvider {
    private static let timerFramePerSecond = 30

    private var disposeBag = DisposeBag()
    private var refreshTimerDisposeBag = DisposeBag()
    private var tasks = Set<AnyTask>()

    private static let normalPriceImpact: Decimal = 1
    private static let warningPriceImpact: Decimal = 5
    private static let forbiddenPriceImpact: Decimal = 20

    private let uniswapProvider: UniswapProvider
    let syncInterval: TimeInterval

    private var swapData: SwapData?

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

    private(set) var tradeType: TradeType = .exactIn {
        didSet {
            if tradeType != oldValue {
                tradeTypeRelay.accept(tradeType)
            }
        }
    }

    private var tradeTypeRelay = PublishRelay<TradeType>()
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

    private let settingsRelay = PublishRelay<UniswapSettings>()
    var settings = UniswapSettings() {
        didSet {
            settingsRelay.accept(settings)
            _ = syncTradeData()
        }
    }

    init(uniswapProvider: UniswapProvider, state: SwapModule.DataSourceState, evmKit: EvmKit.Kit) {
        self.uniswapProvider = uniswapProvider
        syncInterval = evmKit.chain.syncInterval

        tokenIn = state.tokenFrom
        tokenOut = state.tokenTo
        if state.exactFrom {
            amountIn = state.amountFrom ?? 0
        } else {
            amountOut = state.amountTo ?? 0
        }

        evmKit.lastBlockHeightObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] blockNumber in
                    self?.syncSwapData()
                })
                .disposed(by: disposeBag)

        syncSwapData()
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
                    self?.syncSwapData()
                })
                .disposed(by: refreshTimerDisposeBag)
    }

    private func syncSwapData() {
        guard let tokenIn = tokenIn, let tokenOut = tokenOut else {
            state = .notReady(errors: [])
            return
        }

        tasks = Set()
        syncTimer()

//        if swapData == nil {
            state = .loading
//        }

        Task { [weak self, uniswapProvider] in
            do {
                let swapData = try await uniswapProvider.swapData(tokenIn: tokenIn, tokenOut: tokenOut)
                self?.swapData = swapData
                self?.syncTradeData()
            } catch {
                self?.state = .notReady(errors: [error])
            }
        }.store(in: &tasks)
    }

    @discardableResult private func syncTradeData() -> Bool {
        guard let swapData = swapData else {
            return false
        }

        let amount = tradeType == .exactIn ? amountIn : amountOut

        guard amount > 0 else {
            state = .notReady(errors: [])
            return false
        }

        do {
            let tradeData = try uniswapProvider.tradeData(swapData: swapData, amount: amount, tradeType: tradeType, tradeOptions: settings.tradeOptions)
            handle(tradeData: tradeData)
            return true
        } catch {
            var error = error

            if case UniswapKit.Kit.TradeError.tradeNotFound = error {
                let wethAddressString = uniswapProvider.wethAddress.hex

                if case .native = tokenIn?.type, case .eip20(let address) = tokenOut?.type, address == wethAddressString {
                    error = UniswapModule.TradeError.wrapUnwrapNotAllowed
                }

                if case .native = tokenOut?.type, case .eip20(let address) = tokenIn?.type, address == wethAddressString {
                    error = UniswapModule.TradeError.wrapUnwrapNotAllowed
                }
            }

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

extension UniswapTradeService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var countdownTimerObservable: Observable<Float> {
        countdownTimerRelay.asObservable()
    }

    var tradeTypeObservable: Observable<TradeType> {
        tradeTypeRelay.asObservable()
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

    var settingsObservable: Observable<UniswapSettings> {
        settingsRelay.asObservable()
    }

    func transactionData(tradeData: TradeData) throws -> TransactionData {
        try uniswapProvider.transactionData(tradeData: tradeData)
    }

    func set(tokenIn: MarketKit.Token?) {
        guard self.tokenIn != tokenIn else {
            return
        }

        self.tokenIn = tokenIn
        amountIn = 0

        if tradeType == .exactIn {
            amountOut = 0
        }

        if tokenOut == tokenIn {
            tokenOut = nil
            amountOut = 0
        }

        swapData = nil
        syncSwapData()
    }

    func set(tokenOut: MarketKit.Token?) {
        guard self.tokenOut != tokenOut else {
            return
        }

        self.tokenOut = tokenOut
        amountOut = 0

        if tradeType == .exactOut {
            amountIn = 0
        }

        if tokenIn == tokenOut {
            tokenIn = nil
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
        let swapToken = tokenOut
        tokenOut = tokenIn

        set(tokenIn: swapToken)
    }

}

extension UniswapTradeService {

    enum State {
        case loading
        case ready(trade: Trade)
        case notReady(errors: [Error])
    }

    enum PriceImpactLevel: Int {
        case negligible
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
                case 0..<UniswapTradeService.normalPriceImpact: return .negligible
                case UniswapTradeService.normalPriceImpact..<UniswapTradeService.warningPriceImpact: return .normal
                case UniswapTradeService.warningPriceImpact..<UniswapTradeService.forbiddenPriceImpact: return .warning
                default: return .forbidden
                }
            }
        }
    }

}
