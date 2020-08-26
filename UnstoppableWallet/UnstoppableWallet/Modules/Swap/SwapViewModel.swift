import Foundation
import RxSwift
import RxCocoa
import UniswapKit

class SwapViewModel {
    private let disposeBag = DisposeBag()

    private let service: SwapService
    private let factory: SwapViewItemFactory
    private let decimalParser: ISendAmountDecimalParser

    private var isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private var isTradeDataHiddenRelay = BehaviorRelay<Bool>(value: true)
    private var tradeDataErrorRelay = BehaviorRelay<Error?>(value: nil)
    private var tradeViewItemRelay = BehaviorRelay<SwapModule.TradeViewItem?>(value: nil)

    private var balanceRelay = BehaviorRelay<String?>(value: nil)
    private var balanceErrorRelay = BehaviorRelay<Error?>(value: nil)

    private var showProcessRelay = BehaviorRelay<Bool>(value: true)
    private var showApproveRelay = BehaviorRelay<Bool>(value: false)
    private var showApprovingRelay = BehaviorRelay<Bool>(value: false)
    private var isActionEnabledRelay = BehaviorRelay<Bool>(value: false)

    private var openApproveRelay = PublishRelay<SwapModule.ApproveData?>()
    private var closeRelay = PublishRelay<()>()

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
        errors.forEach { error in
            if case SwapValidationError.insufficientBalance = error {
                balanceErrorRelay.accept(error)
                return
            }
        }
    }

    private func resolveTrade(error: Error?) -> Error? {
        guard let error = error else {
            return nil
        }

        if case Kit.TradeError.zeroAmount = error {
            return nil
        }
        return error
    }

    private func handle(tradeData: DataStatus<SwapModule.TradeItem>?) {
        guard let tradeData = tradeData else {  // hide section without trade data
            isTradeDataHiddenRelay.accept(true)
            return
        }

        isTradeDataHiddenRelay.accept(tradeData.isLoading || tradeData.error != nil)
        isLoadingRelay.accept(tradeData.isLoading)

        if let item = tradeData.data {      // show data
            let viewItem = tradeViewItem(item: item)
            tradeViewItemRelay.accept(viewItem)
        }

        tradeDataErrorRelay.accept(resolveTrade(error: tradeData.error))
    }

    private func handle(state: SwapModule.SwapState) {
        switch state {
        case .idle, .allowed:
            showProcessRelay.accept(true)
            isActionEnabledRelay.accept(state == .allowed)
        case .approveRequired:
            showApproveRelay.accept(true)
            isActionEnabledRelay.accept(true)
        case .waitingForApprove:
            showApprovingRelay.accept(true)
            isActionEnabledRelay.accept(false)
        case .swapSuccess:
            closeRelay.accept(())
        }
    }

}

extension SwapViewModel {

    var isLoading: Driver<Bool> {
        isLoadingRelay.asDriver()
    }

    var tradeDataError: Driver<Error?> {
        tradeDataErrorRelay.asDriver()
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

    var balanceError: Driver<Error?> {
        balanceErrorRelay.asDriver()
    }

    var showApprove: Driver<Bool> {
        showApproveRelay.asDriver()
    }

    var showProcess: Driver<Bool> {
        showProcessRelay.asDriver()
    }

    var showApproving: Driver<Bool> {
        showApprovingRelay.asDriver()
    }

    var isActionEnabled: Driver<Bool> {
        isActionEnabledRelay.asDriver()
    }

    var close: Driver<()> {
        closeRelay.asDriver(onErrorJustReturn: ())
    }

    var openApprove: Driver<SwapModule.ApproveData?> {
        openApproveRelay.asDriver(onErrorJustReturn: nil)
    }

    func onTapApprove() {
        openApproveRelay.accept(service.approveData)
    }

    func didApprove() {
        service.didApprove()
    }

    func onSwap() {
        service.swap()
    }

}
