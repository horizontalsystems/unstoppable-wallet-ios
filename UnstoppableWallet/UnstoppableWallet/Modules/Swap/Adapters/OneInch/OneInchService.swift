import RxSwift
import RxRelay
import HsToolKit
import UniswapKit
import CurrencyKit
import BigInt
import EthereumKit
import Foundation
import MarketKit

class OneInchService {
    let dex: SwapModule.Dex
    private let tradeService: OneInchTradeService
    private let allowanceService: SwapAllowanceService
    private let pendingAllowanceService: SwapPendingAllowanceService
    private let adapterManager: AdapterManagerNew

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

    init(dex: SwapModule.Dex, evmKit: EthereumKit.Kit, tradeService: OneInchTradeService, allowanceService: SwapAllowanceService, pendingAllowanceService: SwapPendingAllowanceService, adapterManager: AdapterManagerNew) {
        self.dex = dex
        self.tradeService = tradeService
        self.allowanceService = allowanceService
        self.pendingAllowanceService = pendingAllowanceService
        self.adapterManager = adapterManager

        subscribe(scheduler, disposeBag, tradeService.stateObservable) { [weak self] state in
            self?.onUpdateTrade(state: state)
        }

        subscribe(scheduler, disposeBag, tradeService.platformCoinInObservable) { [weak self] platformCoin in
            self?.onUpdate(platformCoinIn: platformCoin)
        }
        onUpdate(platformCoinIn: tradeService.platformCoinIn)

        subscribe(scheduler, disposeBag, tradeService.platformCoinOutObservable) { [weak self] platformCoin in
            self?.onUpdate(platformCoinOut: platformCoin)
        }

        subscribe(scheduler, disposeBag, tradeService.amountInObservable) { [weak self] amount in
            self?.onUpdate(amountIn: amount)
        }
        subscribe(scheduler, disposeBag, allowanceService.stateObservable) { [weak self] _ in
            self?.syncState()
        }
        subscribe(scheduler, disposeBag, pendingAllowanceService.stateObservable) { [weak self] _ in
            self?.onUpdateAllowanceState()
        }
    }

    private func onUpdateTrade(state: OneInchTradeService.State) {
        syncState()
    }

    private func onUpdate(platformCoinIn: PlatformCoin?) {
        balanceIn = platformCoinIn.flatMap { balance(platformCoin: $0) }
        allowanceService.set(platformCoin: platformCoinIn)
        pendingAllowanceService.set(platformCoin: platformCoinIn)
    }

    private func onUpdate(amountIn: Decimal?) {
        syncState()
    }

    private func onUpdate(platformCoinOut: PlatformCoin?) {
        balanceOut = platformCoinOut.flatMap { balance(platformCoin: $0) }
    }

    private func onUpdateAllowanceState() {
        syncState()
    }

    private func syncState() {
        var allErrors = [Error]()
        var loading = false

        var parameters: OneInchSwapParameters?

        switch tradeService.state {
        case .loading:
            loading = true
        case .ready(let tradeParameters):
            parameters = tradeParameters
        case .notReady(let errors):
            allErrors.append(contentsOf: errors)
        }

        if let allowanceState = allowanceService.state {
            switch allowanceState {
            case .loading:
                loading = true
            case .ready(let allowance):
                if tradeService.amountIn > allowance.value {
                    allErrors.append(SwapModule.SwapError.insufficientAllowance)
                }
            case .notReady(let error):
                allErrors.append(error)
            }
        }

        if let balanceIn = balanceIn {
            if tradeService.amountIn > balanceIn {
                allErrors.append(SwapModule.SwapError.insufficientBalanceIn)
            }
        } else {
            allErrors.append(SwapModule.SwapError.noBalanceIn)
        }

        if pendingAllowanceService.state == .pending {
            loading = true
        }

        errors = allErrors

        if loading {
            state = .loading
        } else if let parameters = parameters, allErrors.isEmpty {
            state = .ready(parameters: parameters)
        } else {
            state = .notReady
        }
    }

    private func balance(platformCoin: PlatformCoin) -> Decimal? {
        (adapterManager.adapter(for: platformCoin) as? IBalanceAdapter)?.balanceData.balance
    }

}

extension OneInchService: ISwapErrorProvider {

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

extension OneInchService {

    enum State: Equatable {
        case loading
        case ready(parameters: OneInchSwapParameters)
        case notReady

        static func ==(lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading): return true
            case (.ready(let lhsParams), .ready(let rhsParams)): return lhsParams == rhsParams
            case (.notReady, .notReady): return true
            default: return false
            }
        }
    }

}
