import RxSwift
import RxRelay
import HsToolKit
import UniswapKit
import CurrencyKit
import BigInt
import EthereumKit
import Foundation

class SwapServiceNew {
    private let ethereumKit: EthereumKit.Kit
    private let tradeService: SwapTradeService
    private let allowanceService: SwapAllowanceService
    private let transactionService: EthereumTransactionService
    private let adapterManager: IAdapterManager

    private let disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .notReady {
        didSet {
            stateRelay.accept(state)
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

    init(ethereumKit: EthereumKit.Kit, tradeService: SwapTradeService, allowanceService: SwapAllowanceService, transactionService: EthereumTransactionService, adapterManager: IAdapterManager) {
        self.ethereumKit = ethereumKit
        self.tradeService = tradeService
        self.allowanceService = allowanceService
        self.transactionService = transactionService
        self.adapterManager = adapterManager

        tradeService.stateObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] state in
                    self?.onUpdateTrade(state: state)
                })
                .disposed(by: disposeBag)

        tradeService.coinInObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] coin in
                    self?.onUpdate(coinIn: coin)
                })
                .disposed(by: disposeBag)

        tradeService.coinOutObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] coin in
                    self?.onUpdate(coinOut: coin)
                })
                .disposed(by: disposeBag)

        tradeService.amountInObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] amount in
                    self?.onUpdate(amountIn: amount)
                })
                .disposed(by: disposeBag)

        allowanceService.stateObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] _ in
                    self?.syncState()
                })
                .disposed(by: disposeBag)

        transactionService.transactionStatusObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] _ in
                    self?.syncState()
                })
                .disposed(by: disposeBag)
    }

    private var ethereumBalance: BigUInt {
        ethereumKit.balance ?? 0
    }

    private func onUpdateTrade(state: SwapTradeService.State) {
        if case .ready(let trade) = state {
            if let kitTransactionData = try? tradeService.transactionData(tradeData: trade.tradeData) { // todo: handle throwing function correctly
                let transactionData = EthereumTransactionService.TransactionData(
                        to: kitTransactionData.to,
                        value: kitTransactionData.value,
                        input: kitTransactionData.input
                )

                transactionService.set(transactionData: transactionData)
            }
        } else {
            transactionService.set(transactionData: nil)
        }

        syncState()
    }

    private func onUpdate(coinIn: Coin?) {
        balanceIn = coinIn.flatMap { balance(coin: $0) }
        allowanceService.set(coin: coinIn)
    }

    private func onUpdate(amountIn: Decimal?) {
        syncState()
    }

    private func onUpdate(coinOut: Coin?) {
        balanceOut = coinOut.flatMap { balance(coin: $0) }
    }

    private func syncState() {
        var allErrors = [Error]()
        var loading = false

        switch tradeService.state {
        case .loading:
            loading = true
        case .ready(let trade):
            if trade.impactLevel == .forbidden {
                allErrors.append(SwapError.forbiddenPriceImpactLevel)
            }
        case .notReady(let errors):
            allErrors.append(contentsOf: errors)
        }

        if let allowanceState = allowanceService.state {
            switch allowanceState {
            case .loading:
                loading = true
            case .ready(let allowance):
                if let amountIn = tradeService.amountIn, amountIn > allowance {
                    allErrors.append(SwapError.insufficientAllowance)
                }
            case .notReady(let error):
                allErrors.append(error)
            }
        }

        switch transactionService.transactionStatus {
        case .loading:
            loading = true
        case .completed(let transaction):
            if transaction.totalAmount > ethereumBalance {
                allErrors.append(TransactionError.insufficientBalance(requiredBalance: transaction.totalAmount))
            }
        case .failed(let error):
            allErrors.append(error)
        }

        if let amountIn = tradeService.amountIn, let balanceIn = balanceIn, amountIn > balanceIn {
            allErrors.append(SwapError.insufficientBalanceIn)
        }

        errors = allErrors

        if loading {
            state = .loading
        } else if allErrors.isEmpty {
            state = .ready
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

extension SwapServiceNew {

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

}

extension SwapServiceNew {

    enum State {
        case loading
        case ready
        case notReady
//        case swapping
//        case swapSuccess
//        case swapError(error: Error)
    }

    enum SwapError: Error {
        case insufficientBalanceIn
        case insufficientAllowance
        case forbiddenPriceImpactLevel
    }

    enum TransactionError: Error {
        case insufficientBalance(requiredBalance: BigUInt)
    }

}
