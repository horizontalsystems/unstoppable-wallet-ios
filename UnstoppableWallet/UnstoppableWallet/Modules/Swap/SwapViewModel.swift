import Foundation
import RxSwift
import RxCocoa
import UniswapKit
import CurrencyKit
import EthereumKit

class SwapViewModel {
    private let disposeBag = DisposeBag()

    public let service: SwapService
    public let tradeService: SwapTradeService
    public let fiatSwitchService: AmountTypeSwitchService
    public let transactionService: EthereumTransactionService
    public let allowanceService: SwapAllowanceService
    public let pendingAllowanceService: SwapPendingAllowanceService
    private let coinService: CoinService

    public let viewItemHelper: SwapViewItemHelper

    private var isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private var swapErrorRelay = BehaviorRelay<String?>(value: nil)
    private var tradeViewItemRelay = BehaviorRelay<TradeViewItem?>(value: nil)
    private var tradeOptionsViewItemRelay = BehaviorRelay<TradeOptionsViewItem?>(value: nil)
    private var advancedSettingsVisibleRelay = BehaviorRelay<Bool>(value: false)
    private var feeVisibleRelay = BehaviorRelay<Bool>(value: false)
    private var proceedActionRelay = BehaviorRelay<ActionState>(value: .hidden)
    private var approveActionRelay = BehaviorRelay<ActionState>(value: .hidden)

    private var openApproveRelay = PublishRelay<SwapAllowanceService.ApproveData>()

    init(service: SwapService, tradeService: SwapTradeService, fiatSwitchService: AmountTypeSwitchService, transactionService: EthereumTransactionService, allowanceService: SwapAllowanceService, pendingAllowanceService: SwapPendingAllowanceService, coinService: CoinService, viewItemHelper: SwapViewItemHelper) {
        self.service = service
        self.tradeService = tradeService
        self.fiatSwitchService = fiatSwitchService
        self.transactionService = transactionService
        self.allowanceService = allowanceService
        self.pendingAllowanceService = pendingAllowanceService
        self.coinService = coinService
        self.viewItemHelper = viewItemHelper

        subscribeToService()

        sync(state: service.state)
        sync(errors: service.errors)
        sync(tradeState: tradeService.state)
    }

    private func subscribeToService() {
        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
        subscribe(disposeBag, service.errorsObservable) { [weak self] in self?.sync(errors: $0) }
        subscribe(disposeBag, tradeService.stateObservable) { [weak self] in self?.sync(tradeState: $0) }
        subscribe(disposeBag, tradeService.swapTradeOptionsObservable) { [weak self] in self?.sync(swapTradeOptions: $0) }
        subscribe(disposeBag, pendingAllowanceService.isPendingObservable) { [weak self] in self?.sync(isApprovePending: $0) }
    }

    private func sync(state: SwapService.State? = nil) {
        let state = state ?? service.state

        isLoadingRelay.accept(state == .loading)
        syncProceedAction()
    }

    private func convert(error: Error) -> String {
        if case SwapService.TransactionError.insufficientBalance(let requiredBalance) = error {
            let amountData = coinService.amountData(value: requiredBalance)
            return "ethereum_transaction.error.insufficient_balance".localized(amountData.formattedString)
        }

        return error.convertedError.smartDescription
    }

    private func sync(errors: [Error]? = nil) {
        let errors = errors ?? service.errors

        let filtered = errors.filter { error in
            switch error {
            case let error as UniswapKit.Kit.TradeError: return error != .zeroAmount
            case _ as EthereumTransactionService.GasDataError: return false
            case _ as SwapService.SwapError: return false
            default: return true
            }
        }

        swapErrorRelay.accept(filtered.first.map { convert(error: $0) })

        syncApproveAction()
        syncProceedAction()
        syncFeeVisible()
    }

    private func sync(tradeState: SwapTradeService.State? = nil) {
        let state = tradeState ?? tradeService.state

        switch state {
        case .ready(let trade):
            tradeViewItemRelay.accept(tradeViewItem(trade: trade))
            advancedSettingsVisibleRelay.accept(true)
        default:
            tradeViewItemRelay.accept(nil)
            advancedSettingsVisibleRelay.accept(false)
        }

        syncProceedAction()
        syncApproveAction()
    }

    private func sync(swapTradeOptions: SwapTradeOptions) {
        tradeOptionsViewItemRelay.accept(tradeOptionsViewItem(swapTradeOptions: swapTradeOptions))
    }

    private func sync(isApprovePending: Bool) {
        syncProceedAction()
        syncApproveAction()
    }

    private func syncProceedAction() {
        if service.state == .ready {
            proceedActionRelay.accept(.enabled(title: "swap.proceed_button".localized))
        } else if case .ready = tradeService.state {
            if service.errors.contains(where: { .insufficientBalanceIn == $0 as? SwapService.SwapError }) {
                proceedActionRelay.accept(.disabled(title: "swap.button_error.insufficient_balance".localized))
            } else if service.errors.contains(where: { .forbiddenPriceImpactLevel == $0 as? SwapService.SwapError }) {
                proceedActionRelay.accept(.disabled(title: "swap.button_error.impact_too_high".localized))
            } else if pendingAllowanceService.isPending == true {
                proceedActionRelay.accept(.hidden)
            } else {
                proceedActionRelay.accept(.disabled(title: "swap.proceed_button".localized))
            }
        } else {
            proceedActionRelay.accept(.hidden)
        }
    }

    private func syncApproveAction() {
        if case .ready = tradeService.state {
            if service.errors.contains(where: { .insufficientBalanceIn == $0 as? SwapService.SwapError || .forbiddenPriceImpactLevel == $0 as? SwapService.SwapError }) {
                approveActionRelay.accept(.hidden)
            } else if pendingAllowanceService.isPending == true {
                approveActionRelay.accept(.disabled(title: "swap.approving_button".localized))
            } else if service.errors.contains(where: { .insufficientAllowance == $0 as? SwapService.SwapError }) {
                approveActionRelay.accept(.enabled(title: "button.approve".localized))
            } else {
                approveActionRelay.accept(.hidden)
            }
        } else {
            approveActionRelay.accept(.hidden)
        }
    }

    private func syncFeeVisible() {
        let allowanceReady: Bool

        if let state = allowanceService.state {
            if case .ready = state {
                allowanceReady = true
            } else {
                allowanceReady = false
            }
        } else {
            allowanceReady = true
        }

        if case .ready = tradeService.state,
           allowanceReady,
           !pendingAllowanceService.isPending,
           !service.errors.contains(where: { $0 is SwapService.SwapError })
        {
            feeVisibleRelay.accept(true)
        } else {
            feeVisibleRelay.accept(false)
        }
    }

    private func tradeViewItem(trade: SwapTradeService.Trade) -> TradeViewItem {
        TradeViewItem(
                executionPrice: viewItemHelper.priceValue(executionPrice: trade.tradeData.executionPrice, coinIn: tradeService.coinIn, coinOut: tradeService.coinOut)?.formattedString,
                priceImpact: viewItemHelper.priceImpactViewItem(trade: trade, minLevel: .warning),
                guaranteedAmount: viewItemHelper.guaranteedAmountViewItem(tradeData: trade.tradeData, coinIn: tradeService.coinIn, coinOut: tradeService.coinOut)
        )
    }

    private func tradeOptionsViewItem(swapTradeOptions: SwapTradeOptions) -> TradeOptionsViewItem {
        TradeOptionsViewItem(slippage: viewItemHelper.slippage(swapTradeOptions.allowedSlippage),
            deadline: viewItemHelper.deadline(swapTradeOptions.ttl),
            recipient: swapTradeOptions.recipient?.title)
    }

}

extension SwapViewModel {

    var isLoadingDriver: Driver<Bool> {
        isLoadingRelay.asDriver()
    }

    var swapErrorDriver: Driver<String?> {
        swapErrorRelay.asDriver()
    }

    var tradeViewItemDriver: Driver<TradeViewItem?> {
        tradeViewItemRelay.asDriver()
    }

    var tradeOptionsViewItemDriver: Driver<TradeOptionsViewItem?> {
        tradeOptionsViewItemRelay.asDriver()
    }

    var advancedSettingsVisibleDriver: Driver<Bool> {
        advancedSettingsVisibleRelay.asDriver()
    }

    var feeVisibleDriver: Driver<Bool> {
        feeVisibleRelay.asDriver()
    }

    var proceedActionDriver: Driver<ActionState> {
        proceedActionRelay.asDriver()
    }

    var approveActionDriver: Driver<ActionState> {
        approveActionRelay.asDriver()
    }

    var openApproveSignal: Signal<SwapAllowanceService.ApproveData> {
        openApproveRelay.asSignal()
    }

    func onTapSwitch() {
        tradeService.switchCoins()
    }

    func onTapApprove() {
        guard let approveData = service.approveData else {
            return
        }

        openApproveRelay.accept(approveData)
    }

    func didApprove() {
        pendingAllowanceService.syncAllowance()
    }

}

extension SwapViewModel {

    struct TradeViewItem {
        let executionPrice: String?
        let priceImpact: SwapModule.PriceImpactViewItem?
        let guaranteedAmount: SwapModule.GuaranteedAmountViewItem?
    }

    struct TradeOptionsViewItem {
        let slippage: String?
        let deadline: String?
        let recipient: String?
    }

    enum ActionState {
        case hidden
        case enabled(title: String)
        case disabled(title: String)
    }

}
