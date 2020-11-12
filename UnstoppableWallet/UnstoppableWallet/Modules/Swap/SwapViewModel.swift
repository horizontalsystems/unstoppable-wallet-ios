import Foundation
import RxSwift
import RxCocoa
import UniswapKit
import CurrencyKit

class SwapViewModel {
    private enum LoadingType: Int, Comparable {
        case allowance
        case tradeData
        case fee
        case waitingForApprove

        static func <(lhs: LoadingType, rhs: LoadingType) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    private enum ValidationErrorType: Int, Comparable, Hashable {
        case fee, validation

        static func <(lhs: ValidationErrorType, rhs: ValidationErrorType) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    private let disposeBag = DisposeBag()

    private let service: SwapService
    private let factory: SwapViewItemHelper
    private let decimalParser: IAmountDecimalParser

    private var isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private var isTradeDataHiddenRelay = BehaviorRelay<Bool>(value: true)
    private var swapErrorRelay = PublishRelay<Error?>()
    private var tradeViewItemRelay = BehaviorRelay<SwapModule.TradeViewItem?>(value: nil)

    private var validationErrorRelay = PublishRelay<Error?>()

    private var showProcessRelay = PublishRelay<()>()
    private var showApproveRelay = PublishRelay<()>()
    private var showApprovingRelay = PublishRelay<()>()
    private var isActionEnabledRelay = PublishRelay<Bool>()

    private var openApproveRelay = PublishRelay<SwapModule.ApproveData?>()
    private var openConfirmationRelay = PublishRelay<()>()
    private var closeRelay = PublishRelay<()>()

    private var validationErrorState = ContainerState<ValidationErrorType, Error>()
    private var loadingState = ContainerState<LoadingType, Bool>()


    // Swap Module Presenters
    public var fromInputPresenter: BaseSwapInputViewModel {
        SwapFromInputViewModel(service: service, decimalParser: decimalParser)
    }

    public var toInputPresenter: BaseSwapInputViewModel {
        SwapToInputViewModel(service: service, decimalParser: decimalParser)
    }

    public var allowancePresenter: SwapAllowanceViewModel {
        SwapAllowanceViewModel(service: service)
    }

    public var tradeOptionsViewModel: SwapTradeOptionsViewModel {
        fatalError()
//        SwapTradeOptionsViewModel(service: SwapTradeOptionsService(tradeOptions: service.tradeOptions), tradeService: tra, decimalParser: AmountDecimalParser())
    }

    init(service: SwapService, factory: SwapViewItemHelper, decimalParser: IAmountDecimalParser) {
        self.service = service
        self.factory = factory
        self.decimalParser = decimalParser

        subscribeToService()
    }

    private func subscribeToService() {
        handle(tradeData: service.tradeDataState)

        subscribe(disposeBag, service.validationErrorsObservable) { [weak self] errors in self?.handle(validationErrors: errors) }
        subscribe(disposeBag, service.tradeDataObservable) { [weak self] in self?.handle(tradeData: $0) }
        subscribe(disposeBag, service.allowanceObservable) { [weak self] in self?.handle(allowance: $0) }
        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.handle(state: $0) }
        subscribe(disposeBag, service.feeStateObservable) { [weak self] in self?.handle(feeState: $0)}
    }

    private func tradeViewItem(item: SwapModule.TradeItem?) -> SwapModule.TradeViewItem? {
        guard let item = item else {
            return nil
        }

        fatalError()
    }

    private func resolveTrade(error: Error?) -> Error? {
        guard let error = error else {
            return nil
        }

        if case UniswapKit.Kit.TradeError.zeroAmount = error {
            return nil
        }
        return error
    }

    private func updateValidationError(type: ValidationErrorType, error: Error?) {
        validationErrorState.set(to: type, value: error)
        validationErrorRelay.accept(validationErrorState.first)
    }
}

extension SwapViewModel {

    private func handle(validationErrors: [Error]) {
        let error = validationErrors.first(where: {
            if case .insufficientFeeBalance(_) = $0 as? FeeModule.FeeError {
                return true
            }
            return false
        })

        updateValidationError(type: .validation, error: error)
    }

    private func handle(tradeData: DataStatus<SwapModule.TradeItem>?) {
        loadingState.set(to: .tradeData, value: tradeData?.isLoading ?? false)
        isLoadingRelay.accept(loadingState.isActive)

        isTradeDataHiddenRelay.accept(tradeData == nil || tradeData?.error != nil || tradeData?.isLoading == true)

        tradeViewItemRelay.accept(tradeViewItem(item: tradeData?.data))

        let resolved = resolveTrade(error: tradeData?.error)
        swapErrorRelay.accept(resolved)
    }

    private func handle(allowance: DataStatus<Decimal>?) {
        loadingState.set(to: .allowance, value: allowance?.isLoading ?? false)

        isLoadingRelay.accept(loadingState.isActive)
    }

    private func handle(state: SwapModule.SwapState) {
        loadingState.set(to: .waitingForApprove, value: false)

        switch state {
        case .idle, .proceedAllowed:
            showProcessRelay.accept(())
            isActionEnabledRelay.accept(state == .proceedAllowed)
        case .approveRequired:
            showApproveRelay.accept(())
            isActionEnabledRelay.accept(true)
        case .waitingForApprove:
            loadingState.set(to: .waitingForApprove, value: true)
            showApprovingRelay.accept(())
            isActionEnabledRelay.accept(false)
        case .swapping:
            ()
        case .swapSuccess:
            closeRelay.accept(())
        }

        isLoadingRelay.accept(loadingState.isActive)
    }

    func handle(feeState: DataStatus<SwapModule.SwapFeeInfo>?) {
        updateValidationError(type: .fee, error: feeState?.error)
        loadingState.set(to: .fee, value: feeState?.isLoading ?? false)
        isLoadingRelay.accept(loadingState.isActive)
    }

}

extension SwapViewModel {

    var isLoading: Driver<Bool> {
        isLoadingRelay.asDriver()
    }

    var swapError: Signal<String?> {
        swapErrorRelay.asSignal().map { $0?.convertedError.smartDescription }
    }

    var tradeViewItem: Driver<SwapModule.TradeViewItem?> {
        tradeViewItemRelay.asDriver()
    }

    var isTradeDataHidden: Driver<Bool> {
        isTradeDataHiddenRelay.asDriver()
    }

    var validationError: Signal<String?> {
        validationErrorRelay.asSignal().map { $0?.convertedError.smartDescription }
    }

    var showApprove: Signal<()> {
        showApproveRelay.asSignal()
    }

    var showProcess: Signal<()> {
        showProcessRelay.asSignal()
    }

    var showApproving: Signal<()> {
        showApprovingRelay.asSignal()
    }

    var isActionEnabled: Signal<Bool> {
        isActionEnabledRelay.asSignal()
    }

    var close: Driver<()> {
        closeRelay.asDriver(onErrorJustReturn: ())
    }

    var openApprove: Signal<SwapModule.ApproveData?> {
        openApproveRelay.asSignal()
    }

    var openConfirmation: Signal<()> {
        openConfirmationRelay.asSignal()
    }

    func onTapSwitch() {
        service.switchCoins()
    }

    func onTapApprove() {
        openApproveRelay.accept(service.approveData)
    }

    func onTapProceed() {
        service.proceed()
    }

    func didApprove() {
        service.didApprove()
    }

    func onSwap() {
        service.swap()
    }

}
