import Foundation
import RxSwift
import RxCocoa
import UniswapKit
import CurrencyKit

class SwapViewModel {
    private enum ErrorType: Int, Comparable, Hashable {
        case tradeData = 0, feeData, validation

        static func <(lhs: ErrorType, rhs: ErrorType) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    private let disposeBag = DisposeBag()

    private let service: SwapService
    private let factory: SwapViewItemFactory
    private let decimalParser: ISendAmountDecimalParser

    private var isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private var isTradeDataHiddenRelay = BehaviorRelay<Bool>(value: true)
    private var swapErrorRelay = PublishRelay<Error?>()
    private var tradeViewItemRelay = BehaviorRelay<SwapModule.TradeViewItem?>(value: nil)

    private var balanceRelay = BehaviorRelay<String?>(value: nil)
    private var balanceErrorRelay = PublishRelay<Error?>()

    private var showProcessRelay = PublishRelay<()>()
    private var showApproveRelay = PublishRelay<()>()
    private var showApprovingRelay = PublishRelay<()>()
    private var isActionEnabledRelay = PublishRelay<Bool>()

    private var openApproveRelay = PublishRelay<SwapModule.ApproveData?>()
    private var openConfirmationRelay = PublishRelay<()>()
    private var closeRelay = PublishRelay<()>()

    private var tradeErrorState = ContainerState<ErrorType, Error>()

    // Swap Module Presenters
    public var fromInputPresenter: BaseSwapInputPresenter {
        SwapFromInputPresenter(service: service, decimalParser: decimalParser)
    }

    public var toInputPresenter: BaseSwapInputPresenter {
        SwapToInputPresenter(service: service, decimalParser: decimalParser)
    }

    public var allowancePresenter: SwapAllowancePresenter {
        SwapAllowancePresenter(service: service)
    }

    public var confirmationPresenter: Swap2ConfirmationPresenter {
        Swap2ConfirmationPresenter(service: service, factory: factory)
    }

    init(service: SwapService, factory: SwapViewItemFactory, decimalParser: ISendAmountDecimalParser) {
        self.service = service
        self.factory = factory
        self.decimalParser = decimalParser

        subscribeToService()
    }

    private func subscribeToService() {
        handle(balance: service.balance)
        handle(tradeData: service.tradeDataState)

        subscribe(disposeBag, service.balanceObservable) { [weak self] in self?.handle(balance: $0) }
        subscribe(disposeBag, service.validationErrorsObservable) { [weak self] errors in self?.handle(errors: errors) }
        subscribe(disposeBag, service.tradeDataObservable) { [weak self] in self?.handle(tradeData: $0) }
        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.handle(state: $0) }
        subscribe(disposeBag, service.feeStateObservable) { [weak self] in self?.handle(feeState: $0)}
    }

    private func tradeViewItem(item: SwapModule.TradeItem) -> SwapModule.TradeViewItem {
        SwapModule.TradeViewItem(
            executionPrice: factory.string(executionPrice: item.executionPrice, coinIn: item.coinIn, coinOut: item.coinOut),
            priceImpact: factory.string(impactPrice: item.priceImpact),
            priceImpactLevel: item.priceImpactLevel,
            minMaxTitle: factory.minMaxTitle(type: item.type, coinOut: item.coinOut),
            minMaxAmount: factory.minMaxValue(amount: item.minMaxAmount, coinIn: item.coinIn, coinOut: item.coinOut, type: item.type))
    }

}

extension SwapViewModel {

    private func updateTradeError(type: ErrorType, error: Error?) {
        tradeErrorState.set(to: type, value: error)

        let tradeDataEmpty = service.tradeDataState?.data == nil
        let hideTrade = tradeErrorState.first != nil || tradeDataEmpty

        isTradeDataHiddenRelay.accept(hideTrade)
        swapErrorRelay.accept(tradeErrorState.first)
    }

    private func handle(balance: Decimal?) {
        guard let balance = balance else {
            balanceRelay.accept(nil)
            return
        }

        let coinValue = CoinValue(coin: service.coinIn, value: balance)
        balanceRelay.accept(ValueFormatter.instance.format(coinValue: coinValue))
    }

    private func handle(errors: [Error]) {
        balanceErrorRelay.accept(nil)
        updateTradeError(type: .validation, error: nil)
        errors.forEach { error in
            if case SwapValidationError.insufficientBalance = error {
                balanceErrorRelay.accept(error)
            }
            if case FeeModule.FeeError.insufficientFeeBalance = error {
                updateTradeError(type: .validation, error: error)
            }
        }
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

    private func handle(tradeData: DataStatus<SwapModule.TradeItem>?) {
        guard let tradeData = tradeData else {  // hide section without trade data
            updateTradeError(type: .tradeData, error: nil)
            return
        }

        isLoadingRelay.accept(tradeData.isLoading)

        if let item = tradeData.data {      // show data
            let viewItem = tradeViewItem(item: item)
            tradeViewItemRelay.accept(viewItem)
        }

        let resolved = resolveTrade(error: tradeData.error)
        updateTradeError(type: .tradeData, error: resolved)
    }

    private func handle(state: SwapModule.SwapState) {
        switch state {
        case .idle, .proceedAllowed:
            isLoadingRelay.accept(false)
            showProcessRelay.accept(())
            isActionEnabledRelay.accept(state == .proceedAllowed)
        case .approveRequired:
            isLoadingRelay.accept(false)
            showApproveRelay.accept(())
            isActionEnabledRelay.accept(true)
        case .waitingForApprove:
            isLoadingRelay.accept(true)
            showApprovingRelay.accept(())
            isActionEnabledRelay.accept(false)
        case .fetchingFee:
            isLoadingRelay.accept(true)
            showProcessRelay.accept(())
            isActionEnabledRelay.accept(false)
        case .swapAllowed:
            isLoadingRelay.accept(false)
            showProcessRelay.accept(())
            isActionEnabledRelay.accept(true)

            openConfirmationRelay.accept(())
        case .swapSuccess:
            closeRelay.accept(())
        }
    }

    func handle(feeState: DataStatus<SwapModule.SwapFeeInfo>?) {
        updateTradeError(type: .feeData, error: feeState?.error)
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

    var balance: Driver<String?> {
        balanceRelay.asDriver()
    }

    var balanceError: Signal<String?> {
        balanceErrorRelay.asSignal().map { $0?.convertedError.smartDescription }
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
