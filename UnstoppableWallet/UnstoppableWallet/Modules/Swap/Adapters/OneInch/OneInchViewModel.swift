import Foundation
import RxSwift
import RxCocoa
import UniswapKit
import CurrencyKit
import EvmKit

class OneInchViewModel {
    private let disposeBag = DisposeBag()
    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.swap_one_inch_view_model", qos: .userInitiated)

    public let service: OneInchService
    public let tradeService: OneInchTradeService
    public let switchService: AmountTypeSwitchService
    private let allowanceService: SwapAllowanceService
    private let pendingAllowanceService: SwapPendingAllowanceService

    private let viewItemHelper: SwapViewItemHelper

    private var isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private var swapErrorRelay = BehaviorRelay<String?>(value: nil)
    private var proceedActionRelay = BehaviorRelay<ActionState>(value: .hidden)
    private var revokeWarningRelay = BehaviorRelay<String?>(value: nil)
    private var revokeActionRelay = BehaviorRelay<ActionState>(value: .hidden)
    private var approveActionRelay = BehaviorRelay<ActionState>(value: .hidden)
    private var approveStepRelay = BehaviorRelay<SwapModule.ApproveStepState>(value: .notApproved)
    private var openConfirmRelay = PublishRelay<OneInchSwapParameters>()

    private var openRevokeRelay = PublishRelay<SwapAllowanceService.ApproveData>()
    private var openApproveRelay = PublishRelay<SwapAllowanceService.ApproveData>()

    init(service: OneInchService, tradeService: OneInchTradeService, switchService: AmountTypeSwitchService, allowanceService: SwapAllowanceService, pendingAllowanceService: SwapPendingAllowanceService, viewItemHelper: SwapViewItemHelper) {
        self.service = service
        self.tradeService = tradeService
        self.switchService = switchService
        self.allowanceService = allowanceService
        self.pendingAllowanceService = pendingAllowanceService
        self.viewItemHelper = viewItemHelper

        subscribeToService()

        handleObservable()
    }

    private func subscribeToService() {
        subscribe(disposeBag, service.stateObservable) { [weak self] _ in self?.handleObservable() }
        subscribe(disposeBag, service.errorsObservable) { [weak self] in self?.handleObservable(errors: $0) }
        subscribe(disposeBag, pendingAllowanceService.stateObservable) { [weak self] _ in self?.handleObservable() }
    }

    private func handleObservable(errors: [Error]? = nil) {
        queue.async { [weak self] in
            if let errors = errors {
                self?.sync(errors: errors)
            }

            self?.syncProceedAction()
            self?.syncApproveAction()
        }
    }

    private func sync(state: OneInchService.State? = nil) {
        let state = state ?? service.state

        isLoadingRelay.accept(state == .loading)
        syncProceedAction()
    }

    private func sync(errors: [Error]? = nil) {
        let errors = errors ?? service.errors

        let filtered = errors.filter { error in
            switch error {
//            case let error as OneInchKit.Kit.TradeError: return error != .zeroAmount
            case _ as EvmFeeModule.GasDataError: return false
            case _ as SwapModule.SwapError: return false
            default: return true
            }
        }

        swapErrorRelay.accept(filtered.first?.convertedError.smartDescription)
    }

    private func syncProceedAction() {
        var actionState = ActionState.disabled(title: "swap.proceed_button".localized)

        if case .ready = service.state {
            actionState = .enabled(title: "swap.proceed_button".localized)
        } else if let error = service.errors.compactMap({ $0 as? SwapModule.SwapError}).first {
            switch error {
            case .insufficientBalanceIn: actionState = .disabled(title: "swap.button_error.insufficient_balance".localized)
            case .needRevokeAllowance:
                switch tradeService.state {
                case .notReady: ()
                default: actionState = .hidden
                }
            default: ()
            }
        } else if case .revoking = pendingAllowanceService.state {
            actionState = .hidden
        }

        proceedActionRelay.accept(actionState)
    }

    private func syncApproveAction() {
        var approveAction: ActionState = .hidden
        var revokeAction: ActionState = .hidden
        var revokeWarning: String?
        let approveStep: SwapModule.ApproveStepState

        for error in service.errors {
            if let allowance = (error as? SwapModule.SwapError)?.revokeAllowance {
                revokeWarning = "swap.revoke_warning".localized(ValueFormatter.instance.formatFull(coinValue: allowance) ?? "n/a".localized)
            }
        }
        if case .pending = pendingAllowanceService.state {
            revokeWarning = nil
            approveAction = .disabled(title: "swap.approving_button".localized)
            approveStep = .approving
        } else if case .revoking = pendingAllowanceService.state {
            revokeWarning = nil
            revokeAction = .disabled(title: "swap.revoking_button".localized)
            approveStep = .revoking
        } else if case .notReady = tradeService.state {
            revokeWarning = nil
            approveStep = .notApproved
        } else if service.errors.contains(where: { .insufficientBalanceIn == $0 as? SwapModule.SwapError }) {
            approveStep = .notApproved
        } else if revokeWarning != nil {
            revokeAction = .enabled(title: "button.revoke".localized)
            approveStep = .revokeRequired
        } else if service.errors.contains(where: { .insufficientAllowance == $0 as? SwapModule.SwapError }) {
            approveAction = .enabled(title: "button.approve".localized)
            approveStep = .approveRequired
        } else if case .approved = pendingAllowanceService.state {
            approveAction = .disabled(title: "button.approve".localized)
            approveStep = .approved
        } else {
            revokeWarning = nil
            approveStep = .notApproved
        }

        revokeWarningRelay.accept(revokeWarning)
        revokeActionRelay.accept(revokeAction)
        approveActionRelay.accept(approveAction)
        approveStepRelay.accept(approveStep)
    }

}

extension OneInchViewModel {

    var isLoadingDriver: Driver<Bool> {
        isLoadingRelay.asDriver()
    }

    var swapErrorDriver: Driver<String?> {
        swapErrorRelay.asDriver()
    }

    var proceedActionDriver: Driver<ActionState> {
        proceedActionRelay.asDriver()
    }

    var revokeWarningDriver: Driver<String?> {
        revokeWarningRelay.asDriver()
    }

    var revokeActionDriver: Driver<ActionState> {
        revokeActionRelay.asDriver()
    }

    var approveActionDriver: Driver<ActionState> {
        approveActionRelay.asDriver()
    }

    var approveStepDriver: Driver<SwapModule.ApproveStepState> {
        approveStepRelay.asDriver()
    }

    var openRevokeSignal: Signal<SwapAllowanceService.ApproveData> {
        openRevokeRelay.asSignal()
    }

    var openApproveSignal: Signal<SwapAllowanceService.ApproveData> {
        openApproveRelay.asSignal()
    }

    var openConfirmSignal: Signal<OneInchSwapParameters> {
        openConfirmRelay.asSignal()
    }

    var dexName: String {
        service.dex.provider.rawValue
    }

    func onTapSwitch() {
        tradeService.switchCoins()
    }

    func onTapRevoke() {
        guard let approveData = service.approveData(amount: 0) else {
            return
        }

        openRevokeRelay.accept(approveData)
    }

    func onTapApprove() {
        guard let approveData = service.approveData() else {
            return
        }

        openApproveRelay.accept(approveData)
    }

    func didApprove() {
        pendingAllowanceService.syncAllowance()
    }

    func onTapProceed() {
        guard case .ready(let parameters) = service.state else {
            return
        }

        openConfirmRelay.accept(parameters)
    }

}

extension OneInchViewModel {

    enum ActionState {
        case hidden
        case enabled(title: String)
        case disabled(title: String)
    }

}
