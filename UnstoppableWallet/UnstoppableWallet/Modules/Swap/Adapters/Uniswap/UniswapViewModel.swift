import Foundation
import RxSwift
import RxCocoa
import UniswapKit
import CurrencyKit
import EthereumKit

class UniswapViewModel {
    private let disposeBag = DisposeBag()

    public let service: UniswapService
    public let tradeService: UniswapTradeService
    public let switchService: AmountTypeSwitchService
    private let allowanceService: SwapAllowanceService
    private let pendingAllowanceService: SwapPendingAllowanceService

    private let viewItemHelper: SwapViewItemHelper

    private var isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private var swapErrorRelay = BehaviorRelay<String?>(value: nil)
    private var tradeViewItemRelay = BehaviorRelay<TradeViewItem?>(value: nil)
    private var settingsViewItemRelay = BehaviorRelay<SettingsViewItem?>(value: nil)
    private var proceedActionRelay = BehaviorRelay<ActionState>(value: .hidden)
    private var approveActionRelay = BehaviorRelay<ActionState>(value: .hidden)
    private var openConfirmRelay = PublishRelay<SendEvmData>()

    private var openApproveRelay = PublishRelay<SwapAllowanceService.ApproveData>()

    private let scheduler = SerialDispatchQueueScheduler(qos: .userInitiated, internalSerialQueueName: "io.horizontalsystems.unstoppable.swap_view_model")

    init(service: UniswapService, tradeService: UniswapTradeService, switchService: AmountTypeSwitchService, allowanceService: SwapAllowanceService, pendingAllowanceService: SwapPendingAllowanceService, viewItemHelper: SwapViewItemHelper) {
        self.service = service
        self.tradeService = tradeService
        self.switchService = switchService
        self.allowanceService = allowanceService
        self.pendingAllowanceService = pendingAllowanceService
        self.viewItemHelper = viewItemHelper

        subscribeToService()

        sync(state: service.state)
        sync(errors: service.errors)
        sync(tradeState: tradeService.state)
    }

    private func subscribeToService() {
        subscribe(scheduler, disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
        subscribe(scheduler, disposeBag, service.errorsObservable) { [weak self] in self?.sync(errors: $0) }
        subscribe(scheduler, disposeBag, tradeService.stateObservable) { [weak self] in self?.sync(tradeState: $0) }
        subscribe(scheduler, disposeBag, tradeService.settingsObservable) { [weak self] in self?.sync(swapSettings: $0) }
        subscribe(scheduler, disposeBag, pendingAllowanceService.isPendingObservable) { [weak self] in self?.sync(isApprovePending: $0) }
    }

    private func sync(state: UniswapService.State? = nil) {
        let state = state ?? service.state

        isLoadingRelay.accept(state == .loading)
        syncProceedAction()
    }

    private func sync(errors: [Error]? = nil) {
        let errors = errors ?? service.errors

        let filtered = errors.filter { error in
            switch error {
            case let error as UniswapKit.Kit.TradeError: return error != .zeroAmount
            case _ as EvmTransactionService.GasDataError: return false
            case _ as SwapModule.SwapError: return false
            default: return true
            }
        }

        swapErrorRelay.accept(filtered.first?.convertedError.smartDescription)

        syncApproveAction()
        syncProceedAction()
    }

    private func sync(tradeState: UniswapTradeService.State) {
        switch tradeState {
        case .ready(let trade):
            tradeViewItemRelay.accept(tradeViewItem(trade: trade))
        default:
            tradeViewItemRelay.accept(nil)
        }

        syncProceedAction()
        syncApproveAction()
    }

    private func sync(swapSettings: UniswapSettings) {
        settingsViewItemRelay.accept(settingsViewItem(settings: swapSettings))
    }

    private func sync(isApprovePending: Bool) {
        syncProceedAction()
        syncApproveAction()
    }

    private func syncProceedAction() {
        if case .ready = service.state {
            proceedActionRelay.accept(.enabled(title: "swap.proceed_button".localized))
        } else if case .ready = tradeService.state {
            if service.errors.contains(where: { .insufficientBalanceIn == $0 as? SwapModule.SwapError }) {
                proceedActionRelay.accept(.disabled(title: "swap.button_error.insufficient_balance".localized))
            } else if service.errors.contains(where: { .forbiddenPriceImpactLevel == $0 as? SwapModule.SwapError }) {
                proceedActionRelay.accept(.disabled(title: "swap.button_error.impact_too_high".localized))
            } else if pendingAllowanceService.isPending == true {
                proceedActionRelay.accept(.disabled(title: "swap.proceed_button".localized))
            } else {
                proceedActionRelay.accept(.disabled(title: "swap.proceed_button".localized))
            }
        } else {
            proceedActionRelay.accept(.disabled(title: "swap.proceed_button".localized))
        }
    }

    private func syncApproveAction() {
        if case .ready = tradeService.state {
            if service.errors.contains(where: { .insufficientBalanceIn == $0 as? SwapModule.SwapError || .forbiddenPriceImpactLevel == $0 as? SwapModule.SwapError }) {
                approveActionRelay.accept(.hidden)
            } else if pendingAllowanceService.isPending == true {
                approveActionRelay.accept(.disabled(title: "swap.approving_button".localized))
            } else if service.errors.contains(where: { .insufficientAllowance == $0 as? SwapModule.SwapError }) {
                approveActionRelay.accept(.enabled(title: "button.approve".localized))
            } else {
                approveActionRelay.accept(.hidden)
            }
        } else {
            approveActionRelay.accept(.hidden)
        }
    }

    private func tradeViewItem(trade: UniswapTradeService.Trade) -> TradeViewItem {
        TradeViewItem(
                executionPrice: viewItemHelper.priceValue(executionPrice: trade.tradeData.executionPrice, coinIn: tradeService.coinIn, coinOut: tradeService.coinOut)?.formattedString,
                priceImpact: viewItemHelper.priceImpactViewItem(trade: trade, minLevel: .warning),
                guaranteedAmount: viewItemHelper.guaranteedAmountViewItem(tradeData: trade.tradeData, coinIn: tradeService.coinIn, coinOut: tradeService.coinOut)
        )
    }

    private func settingsViewItem(settings: UniswapSettings) -> SettingsViewItem {
        SettingsViewItem(slippage: viewItemHelper.slippage(settings.allowedSlippage),
            deadline: viewItemHelper.deadline(settings.ttl),
            recipient: settings.recipient?.title)
    }

}

extension UniswapViewModel {

    var isLoadingDriver: Driver<Bool> {
        isLoadingRelay.asDriver()
    }

    var swapErrorDriver: Driver<String?> {
        swapErrorRelay.asDriver()
    }

    var tradeViewItemDriver: Driver<TradeViewItem?> {
        tradeViewItemRelay.asDriver()
    }

    var settingsViewItemDriver: Driver<SettingsViewItem?> {
        settingsViewItemRelay.asDriver()
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

    var openConfirmSignal: Signal<SendEvmData> {
        openConfirmRelay.asSignal()
    }

    var dexName: String {
        service.dex.provider.rawValue
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

    func onTapProceed() {
        guard case .ready(let transactionData) = service.state else {
            return
        }

        guard case let .ready(trade) = tradeService.state else {
            return
        }

        let swapInfo = SendEvmData.SwapInfo(
                estimatedOut: tradeService.amountOut,
                estimatedIn: tradeService.amountIn,
                slippage: viewItemHelper.slippage(tradeService.settings.allowedSlippage),
                deadline: viewItemHelper.deadline(tradeService.settings.ttl),
                recipientDomain: tradeService.settings.recipient?.domain,
                price: viewItemHelper.priceValue(executionPrice: trade.tradeData.executionPrice, coinIn: tradeService.coinIn, coinOut: tradeService.coinOut)?.formattedString,
                priceImpact: viewItemHelper.priceImpactViewItem(trade: trade)?.value
        )

        openConfirmRelay.accept(SendEvmData(transactionData: transactionData, additionalInfo: .swap(info: swapInfo)))
    }

}

extension UniswapViewModel {

    struct TradeViewItem {
        let executionPrice: String?
        let priceImpact: UniswapModule.PriceImpactViewItem?
        let guaranteedAmount: UniswapModule.GuaranteedAmountViewItem?
    }

    struct SettingsViewItem {
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
