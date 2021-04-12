import RxSwift
import RxRelay
import HsToolKit
import UniswapKit
import CurrencyKit
import BigInt
import EthereumKit
import Foundation
import CoinKit

class SwapService {
    let dex: SwapModule.Dex
    private let evmKit: EthereumKit.Kit
    private let tradeService: SwapTradeService
    private let allowanceService: SwapAllowanceService
    private let pendingAllowanceService: SwapPendingAllowanceService
    private let adapterManager: IAdapterManager

    private let disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .notReady {
        didSet {
            if oldValue != state {
                stateRelay.accept(state)
            }
        }
    }

    private let errorsRelay = PublishRelay<[Error]>()
    private(set) var errors: [Error] = [] {
        didSet {
            errorsRelay.accept(errors)
        }
    }

    private let balanceInRelay = PublishRelay<Decimal?>()
    private(set) var balanceIn: Decimal? {
        didSet {
            balanceInRelay.accept(balanceIn)
        }
    }

    private let balanceOutRelay = PublishRelay<Decimal?>()
    private(set) var balanceOut: Decimal? {
        didSet {
            balanceOutRelay.accept(balanceOut)
        }
    }

    private let scheduler = SerialDispatchQueueScheduler(qos: .userInitiated, internalSerialQueueName: "io.horizontalsystems.unstoppable.swap_service")

    init(dex: SwapModule.Dex, evmKit: EthereumKit.Kit, tradeService: SwapTradeService, allowanceService: SwapAllowanceService, pendingAllowanceService: SwapPendingAllowanceService, adapterManager: IAdapterManager) {
        self.dex = dex
        self.evmKit = evmKit
        self.tradeService = tradeService
        self.allowanceService = allowanceService
        self.pendingAllowanceService = pendingAllowanceService
        self.adapterManager = adapterManager

        subscribe(scheduler, disposeBag, tradeService.stateObservable) { [weak self] state in
            self?.onUpdateTrade(state: state)
        }

        subscribe(scheduler, disposeBag, tradeService.coinInObservable) { [weak self] coin in
            self?.onUpdate(coinIn: coin)
        }
        onUpdate(coinIn: tradeService.coinIn)

        subscribe(scheduler, disposeBag, tradeService.coinOutObservable) { [weak self] coin in
            self?.onUpdate(coinOut: coin)
        }

        subscribe(scheduler, disposeBag, tradeService.amountInObservable) { [weak self] amount in
            self?.onUpdate(amountIn: amount)
        }
        subscribe(scheduler, disposeBag, allowanceService.stateObservable) { [weak self] _ in
            self?.syncState()
        }
        subscribe(scheduler, disposeBag, pendingAllowanceService.isPendingObservable) { [weak self] isPending in
            self?.onUpdate(isAllowancePending: isPending)
        }
    }

    private func onUpdateTrade(state: SwapTradeService.State) {
        syncState()
    }

    private func onUpdate(coinIn: Coin?) {
        balanceIn = coinIn.flatMap { balance(coin: $0) }
        allowanceService.set(coin: coinIn)
        pendingAllowanceService.set(coin: coinIn)
    }

    private func onUpdate(amountIn: Decimal?) {
        syncState()
    }

    private func onUpdate(coinOut: Coin?) {
        balanceOut = coinOut.flatMap { balance(coin: $0) }
    }

    private func onUpdate(isAllowancePending: Bool) {
        syncState()
    }

    private func syncState() {
        var allErrors = [Error]()
        var loading = false

        var transactionData: TransactionData?

        switch tradeService.state {
        case .loading:
            loading = true
        case .ready(let trade):
            if let impactLevel = trade.impactLevel, impactLevel == .forbidden {
                allErrors.append(SwapError.forbiddenPriceImpactLevel)
            }

            transactionData = try? tradeService.transactionData(tradeData: trade.tradeData)
        case .notReady(let errors):
            allErrors.append(contentsOf: errors)
        }

        if let allowanceState = allowanceService.state {
            switch allowanceState {
            case .loading:
                loading = true
            case .ready(let allowance):
                if tradeService.amountIn > allowance.value {
                    allErrors.append(SwapError.insufficientAllowance)
                }
            case .notReady(let error):
                allErrors.append(error)
            }
        }

        if let balanceIn = balanceIn {
            if tradeService.amountIn > balanceIn {
                allErrors.append(SwapError.insufficientBalanceIn)
            }
        } else {
            allErrors.append(SwapError.noBalanceIn)
        }

        if pendingAllowanceService.isPending {
            loading = true
        }

        errors = allErrors

        if loading {
            state = .loading
        } else if let transactionData = transactionData, allErrors.isEmpty {
            state = .ready(transactionData: transactionData)
        } else {
            state = .notReady
        }
    }

    private func balance(coin: Coin) -> Decimal? {
        guard let adapter = adapterManager.adapter(for: coin) as? IBalanceAdapter else {
            return nil
        }

        return adapter.balance
    }

}

extension SwapService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var errorsObservable: Observable<[Error]> {
        errorsRelay.asObservable()
    }

    var balanceInObservable: Observable<Decimal?> {
        balanceInRelay.asObservable()
    }

    var balanceOutObservable: Observable<Decimal?> {
        balanceOutRelay.asObservable()
    }

    var approveData: SwapAllowanceService.ApproveData? {
        guard let amount = balanceIn else {
            return nil
        }

        return allowanceService.approveData(dex: dex, amount: amount)
    }

}

extension SwapService {

    enum State: Equatable {
        case loading
        case ready(transactionData: TransactionData)
        case notReady

        static func ==(lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading): return true
            case (.ready(let lhsTransactionData), .ready(let rhsTransactionData)): return lhsTransactionData == rhsTransactionData
            case (.notReady, .notReady): return true
            default: return false
            }
        }
    }

    enum SwapError: Error {
        case noBalanceIn
        case insufficientBalanceIn
        case insufficientAllowance
        case forbiddenPriceImpactLevel
    }

}
