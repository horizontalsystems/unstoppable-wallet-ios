import Foundation
import EthereumKit
import UniswapKit
import RxSwift
import RxRelay
import MarketKit

class UniswapTradeService {
    private var disposeBag = DisposeBag()
    private static let warningPriceImpact: Decimal = 1
    private static let forbiddenPriceImpact: Decimal = 5

    private let uniswapProvider: UniswapProvider

    private var swapDataDisposeBag = DisposeBag()

    private var swapData: SwapData?

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

    private(set) var tradeType: TradeType = .exactIn {
        didSet {
            if tradeType != oldValue {
                tradeTypeRelay.accept(tradeType)
            }
        }
    }

    private var tradeTypeRelay = PublishRelay<TradeType>()
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

    private let settingsRelay = PublishRelay<UniswapSettings>()
    var settings = UniswapSettings() {
        didSet {
            settingsRelay.accept(settings)
            _ = syncTradeData()
        }
    }

    init(uniswapProvider: UniswapProvider, state: SwapModule.DataSourceState, evmKit: EthereumKit.Kit) {
        self.uniswapProvider = uniswapProvider
        platformCoinIn = state.platformCoinFrom
        platformCoinOut = state.platformCoinTo
        if state.exactFrom {
            amountIn = state.amountFrom ?? 0
        } else {
            amountOut = state.amountTo ?? 0
        }

        syncSwapData()

        evmKit.lastBlockHeightObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] blockNumber in
                    self?.syncSwapData()
                })
                .disposed(by: disposeBag)
    }

    private func syncSwapData() {
        guard let platformCoinIn = platformCoinIn, let platformCoinOut = platformCoinOut else {
            state = .notReady(errors: [])
            return
        }

        swapDataDisposeBag = DisposeBag()

        if swapData == nil {
            state = .loading
        }

        uniswapProvider
                .swapDataSingle(platformCoinIn: platformCoinIn, platformCoinOut: platformCoinOut)
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
            let tradeData = try uniswapProvider.tradeData(swapData: swapData, amount: amount, tradeType: tradeType, tradeOptions: settings.tradeOptions)
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

extension UniswapTradeService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var tradeTypeObservable: Observable<TradeType> {
        tradeTypeRelay.asObservable()
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

    var settingsObservable: Observable<UniswapSettings> {
        settingsRelay.asObservable()
    }

    func transactionData(tradeData: TradeData) throws -> TransactionData {
        try uniswapProvider.transactionData(tradeData: tradeData)
    }

    func set(platformCoinIn: PlatformCoin?) {
        guard self.platformCoinIn != platformCoinIn else {
            return
        }

        self.platformCoinIn = platformCoinIn
        amountIn = 0

        if tradeType == .exactIn {
            amountOut = 0
        }

        if platformCoinOut == platformCoinIn {
            platformCoinOut = nil
            amountOut = 0
        }

        swapData = nil
        syncSwapData()
    }

    func set(platformCoinOut: PlatformCoin?) {
        guard self.platformCoinOut != platformCoinOut else {
            return
        }

        self.platformCoinOut = platformCoinOut
        amountOut = 0

        if tradeType == .exactOut {
            amountIn = 0
        }

        if platformCoinIn == platformCoinOut {
            platformCoinIn = nil
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
        let swapPlatformCoin = platformCoinOut
        platformCoinOut = platformCoinIn

        set(platformCoinIn: swapPlatformCoin)
    }

}

extension UniswapTradeService {

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
                case 0..<UniswapTradeService.warningPriceImpact: return .normal
                case UniswapTradeService.warningPriceImpact..<UniswapTradeService.forbiddenPriceImpact: return .warning
                default: return .forbidden
                }
            }
        }
    }

}
