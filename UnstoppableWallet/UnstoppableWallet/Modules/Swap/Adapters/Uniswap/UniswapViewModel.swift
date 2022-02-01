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
    private var approveStepRelay = BehaviorRelay<SwapModule.ApproveStepState>(value: .notApproved)
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
        subscribe(scheduler, disposeBag, pendingAllowanceService.stateObservable) { [weak self] _ in self?.syncPendingAllowanceState() }
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
            case _ as EvmFeeModule.GasDataError: return false
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

    private func syncPendingAllowanceState() {
        syncProceedAction()
        syncApproveAction()
    }

    private func syncProceedAction() {
        if case .ready = service.state {
            proceedActionRelay.accept(.enabled(title: "swap.proceed_button".localized))
        } else if case .ready = tradeService.state {
            if service.errors.contains(where: { .insufficientBalanceIn == $0 as? SwapModule.SwapError }) {
                proceedActionRelay.accept(.disabled(title: "swap.button_error.insufficient_balance".localized))
            } else if pendingAllowanceService.state == .pending {
                proceedActionRelay.accept(.disabled(title: "swap.proceed_button".localized))
            } else {
                proceedActionRelay.accept(.disabled(title: "swap.proceed_button".localized))
            }
        } else {
            proceedActionRelay.accept(.disabled(title: "swap.proceed_button".localized))
        }
    }

    private func syncApproveAction() {
        let approveAction: ActionState
        let approveStep: SwapModule.ApproveStepState

        if case .pending = pendingAllowanceService.state {
            approveAction = .disabled(title: "swap.approving_button".localized)
            approveStep = .approving
        } else if case .notReady = tradeService.state {
            approveAction = .hidden
            approveStep = .notApproved
        } else if service.errors.contains(where: { .insufficientBalanceIn == $0 as? SwapModule.SwapError }) {
            approveAction = .hidden
            approveStep = .notApproved
        } else if service.errors.contains(where: { .insufficientAllowance == $0 as? SwapModule.SwapError }) {
            approveAction = .enabled(title: "button.approve".localized)
            approveStep = .approveRequired
        } else if case .approved = pendingAllowanceService.state {
            approveAction = .disabled(title: "button.approve".localized)
            approveStep = .approved
        } else {
            approveAction = .hidden
            approveStep = .notApproved
        }

        approveActionRelay.accept(approveAction)
        approveStepRelay.accept(approveStep)
    }

    private func tradeViewItem(trade: UniswapTradeService.Trade) -> TradeViewItem {
        TradeViewItem(
                executionPrice: viewItemHelper.priceValue(executionPrice: trade.tradeData.executionPrice, platformCoinIn: tradeService.platformCoinIn, platformCoinOut: tradeService.platformCoinOut)?.formattedString,
                executionPriceInverted: viewItemHelper.priceValue(executionPrice: trade.tradeData.executionPriceInverted, platformCoinIn: tradeService.platformCoinOut, platformCoinOut: tradeService.platformCoinIn)?.formattedString,
                priceImpact: viewItemHelper.priceImpactViewItem(trade: trade, minLevel: .warning),
                guaranteedAmount: viewItemHelper.guaranteedAmountViewItem(tradeData: trade.tradeData, platformCoinIn: tradeService.platformCoinIn, platformCoinOut: tradeService.platformCoinOut)
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

    var approveStepDriver: Driver<SwapModule.ApproveStepState> {
        approveStepRelay.asDriver()
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
                price: viewItemHelper.priceValue(executionPrice: trade.tradeData.executionPrice, platformCoinIn: tradeService.platformCoinIn, platformCoinOut: tradeService.platformCoinOut)?.formattedString,
                priceImpact: viewItemHelper.priceImpactViewItem(trade: trade)
        )

        let sendEvmData = SendEvmData(
                transactionData: transactionData, additionalInfo: .uniswap(info: swapInfo),
                warnings: trade.impactLevel == .forbidden ? [UniswapModule.UniswapWarning.highPriceImpact] : []
        )

        openConfirmRelay.accept(sendEvmData)
    }

}

extension UniswapViewModel {

    struct TradeViewItem {
        let executionPrice: String?
        let executionPriceInverted: String?
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
