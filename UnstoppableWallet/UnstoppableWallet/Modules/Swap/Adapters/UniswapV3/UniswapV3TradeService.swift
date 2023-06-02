import Combine
import Foundation
import EvmKit
import UniswapKit
import RxSwift
import RxRelay
import MarketKit
import HsExtensions

class UniswapV3TradeService: ISwapSettingProvider {
    private static let timerFramePerSecond: Int = 30

    private var disposeBag = DisposeBag()

    private var refreshTimerTask: AnyTask?
    private var refreshTimerCancellable: Cancellable?
    private var refreshTimerDisposeBag = DisposeBag()

    private var cancellables = Set<AnyCancellable>()
    private var tasks = Set<AnyTask>()

    private static let normalPriceImpact: Decimal = 1
    private static let warningPriceImpact: Decimal = 5
    private static let forbiddenPriceImpact: Decimal = 20

    private let uniswapProvider: UniswapV3Provider
    let syncInterval: TimeInterval

    private var bestTrade: TradeDataV3?

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

    init(uniswapProvider: UniswapV3Provider, state: SwapModule.DataSourceState, evmKit: EvmKit.Kit) {
        self.uniswapProvider = uniswapProvider
        syncInterval = evmKit.chain.syncInterval

        tokenIn = state.tokenFrom
        tokenOut = state.tokenTo
        if state.exactFrom {
            amountIn = state.amountFrom ?? 0
        } else {
            amountOut = state.amountTo ?? 0
        }

        evmKit.lastBlockHeightPublisher
                .sink { [weak self] blockNumber in
                    self?.syncTradeData()
                }
                .store(in: &cancellables)

        syncTradeData()
    }

    private func syncTimer() {
        refreshTimerTask?.cancel()
        let tickerCount = Int(syncInterval) * Self.timerFramePerSecond

        refreshTimerTask = Task { [weak self] in
            for i in 0...tickerCount {
                try await Task.sleep(nanoseconds: 1_000_000_000 / UInt64(Self.timerFramePerSecond))
                self?.countdownTimerRelay.accept(Float(i) / Float(tickerCount))
            }

            self?.syncTradeData()
        }.erased()
    }

    @discardableResult private func syncTradeData() -> Bool {
        guard let tokenIn = tokenIn,
              let tokenOut = tokenOut else {
            state = .notReady(errors: [])
            return false
        }

        tasks = Set()
        syncTimer()

        state = .loading

        let amount = tradeType == .exactIn ? amountIn : amountOut

        guard amount > 0 else {
            state = .notReady(errors: [])
            return false
        }

        Task { [weak self, uniswapProvider, tradeType, settings] in
            do {
                let bestTrade = try await uniswapProvider.bestTrade(tokenIn: tokenIn, tokenOut: tokenOut, amount: amount, tradeType: tradeType, tradeOptions: settings.tradeOptions)
                self?.handle(tradeData: bestTrade)
            } catch {
                var convertedError = error

                if case UniswapKit.KitV3.TradeError.tradeNotFound = error {
                    let wethAddressString = uniswapProvider.wethAddress.hex

                    if case .native = tokenIn.type, case .eip20(let address) = tokenOut.type, address == wethAddressString {
                        convertedError = UniswapModule.TradeError.wrapUnwrapNotAllowed
                    }

                    if case .native = tokenOut.type, case .eip20(let address) = tokenIn.type, address == wethAddressString {
                        convertedError = UniswapModule.TradeError.wrapUnwrapNotAllowed
                    }
                }

                self?.state = .notReady(errors: [convertedError])
            }
        }.store(in: &tasks)

        return true
    }

    private func handle(tradeData: TradeDataV3) {
        bestTrade = tradeData

        switch tradeData.type {
        case .exactIn:
            amountOut = tradeData.amountOut ?? 0
        case .exactOut:
            amountIn = tradeData.amountIn ?? 0
        }

        let trade = Trade(tradeData: tradeData)
        state = .ready(trade: trade)
    }

}

protocol IUniswapTradeService {
    var stateObservable: Observable<UniswapTradeService.State> { get }

}

extension UniswapV3TradeService {

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

    func transactionData(tradeData: TradeDataV3) throws -> TransactionData {
        try uniswapProvider.transactionData(tradeData: tradeData, tradeOptions: settings.tradeOptions)
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

        bestTrade = nil
        syncTradeData()
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

        bestTrade = nil
        syncTradeData()
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

extension UniswapV3TradeService {

    enum State {
        case loading
        case ready(trade: Trade)
        case notReady(errors: [Error])
    }

    struct Trade {
        let tradeData: TradeDataV3
        let impactLevel: UniswapTradeService.PriceImpactLevel?

        init(tradeData: TradeDataV3) {
            self.tradeData = tradeData

            impactLevel = tradeData.priceImpact.map { priceImpact in
                if priceImpact < UniswapV3TradeService.normalPriceImpact {
                    return .negligible
                }
                if priceImpact < UniswapV3TradeService.warningPriceImpact {
                    return .normal
                }
                if priceImpact < UniswapV3TradeService.forbiddenPriceImpact {
                    return .warning
                }
                return .forbidden
            }
        }
    }

}
