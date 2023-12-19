import BigInt
import EvmKit
import Foundation
import HsToolKit
import MarketKit
import RxRelay
import RxSwift
import UniswapKit

class UniswapV3Service {
    let dex: SwapModule.Dex
    private let tradeService: UniswapV3TradeService
    private let allowanceService: SwapAllowanceService
    private let pendingAllowanceService: SwapPendingAllowanceService
    private let adapterManager: AdapterManager

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
            if oldValue.isEmpty, errors.isEmpty {
                return
            }
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

    private let scheduler = SerialDispatchQueueScheduler(qos: .userInitiated, internalSerialQueueName: "\(AppConfig.label).swap_service")

    init(dex: SwapModule.Dex, tradeService: UniswapV3TradeService, allowanceService: SwapAllowanceService, pendingAllowanceService: SwapPendingAllowanceService, adapterManager: AdapterManager) {
        self.dex = dex
        self.tradeService = tradeService
        self.allowanceService = allowanceService
        self.pendingAllowanceService = pendingAllowanceService
        self.adapterManager = adapterManager

        subscribe(scheduler, disposeBag, tradeService.stateObservable) { [weak self] state in
            self?.onUpdateTrade(state: state)
        }

        subscribe(scheduler, disposeBag, tradeService.tokenInObservable) { [weak self] token in
            self?.onUpdate(token: token)
        }
        onUpdate(token: tradeService.tokenIn)

        subscribe(scheduler, disposeBag, tradeService.tokenOutObservable) { [weak self] token in
            self?.onUpdate(tokenOut: token)
        }

        subscribe(scheduler, disposeBag, tradeService.amountInObservable) { [weak self] amount in
            self?.onUpdate(amountIn: amount)
        }
        subscribe(scheduler, disposeBag, allowanceService.stateObservable) { [weak self] _ in
            self?.syncState()
        }
        subscribe(scheduler, disposeBag, pendingAllowanceService.stateObservable) { [weak self] _ in
            self?.onUpdatePendingAllowanceState()
        }
    }

    private func onUpdateTrade(state _: UniswapV3TradeService.State) {
        syncState()
    }

    private func onUpdate(token: MarketKit.Token?) {
        balanceIn = token.flatMap { balance(token: $0) }
        allowanceService.set(token: token)
        pendingAllowanceService.set(token: token)
    }

    private func onUpdate(amountIn _: Decimal?) {
        syncState()
    }

    private func onUpdate(tokenOut: MarketKit.Token?) {
        balanceOut = tokenOut.flatMap { balance(token: $0) }
    }

    private func onUpdatePendingAllowanceState() {
        syncState()
    }

    private func checkAllowanceError(allowance: CoinValue) -> Error? {
        guard let balanceIn,
              balanceIn >= tradeService.amountIn,
              tradeService.amountIn > allowance.value
        else {
            return nil
        }

        if SwapModule.mustBeRevoked(token: tradeService.tokenIn), allowance.value != 0 {
            return SwapModule.SwapError.needRevokeAllowance(allowance: allowance)
        }

        return SwapModule.SwapError.insufficientAllowance
    }

    private func syncState() {
        var allErrors = [Error]()
        var loading = false

        var transactionData: TransactionData?

        switch tradeService.state {
        case .loading:
            loading = true
        case let .ready(trade):
            transactionData = try? tradeService.transactionData(tradeData: trade.tradeData)
        case let .notReady(errors):
            allErrors.append(contentsOf: errors)
        }

        if let allowanceState = allowanceService.state {
            switch allowanceState {
            case .loading:
                loading = true
            case let .ready(allowance):
                if let error = checkAllowanceError(allowance: allowance) {
                    allErrors.append(error)
                }
            case let .notReady(error):
                allErrors.append(error)
            }
        }

        if let balanceIn {
            if tradeService.amountIn > balanceIn {
                allErrors.append(SwapModule.SwapError.insufficientBalanceIn)
            }
        } else {
            allErrors.append(SwapModule.SwapError.noBalanceIn)
        }

        if pendingAllowanceService.state == .pending {
            loading = true
        }

        if !loading {
            errors = allErrors
        }

        if loading {
            state = .loading
        } else if let transactionData, allErrors.isEmpty {
            state = .ready(transactionData: transactionData)
        } else {
            state = .notReady
        }
    }

    private func balance(token: MarketKit.Token) -> Decimal? {
        (adapterManager.adapter(for: token) as? IBalanceAdapter)?.balanceData.available
    }
}

extension UniswapV3Service: ISwapErrorProvider {
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

    func approveData(amount: Decimal? = nil) -> SwapAllowanceService.ApproveData? {
        let amount = amount ?? balanceIn
        guard let amount else {
            return nil
        }

        return allowanceService.approveData(dex: dex, amount: amount)
    }
}

extension UniswapV3Service {
    enum State: Equatable {
        case loading
        case ready(transactionData: TransactionData)
        case notReady

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading): return true
            case let (.ready(lhsTransactionData), .ready(rhsTransactionData)): return lhsTransactionData == rhsTransactionData
            case (.notReady, .notReady): return true
            default: return false
            }
        }
    }
}
