import Foundation
import RxSwift
import RxCocoa
import UniswapKit

class SwapViewModel {
    private let disposeBag = DisposeBag()

    private let service: SwapService
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
    private var openProceedRelay = PublishRelay<SwapModule.ProceedData?>()

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

    init(service: SwapService, decimalParser: ISendAmountDecimalParser) {
        self.service = service
        self.decimalParser = decimalParser

        subscribeToService()
    }

    private func subscribeToService() {
        subscribe(disposeBag, service.balance) { [weak self] in self?.handle(balance: $0) }
        subscribe(disposeBag, service.validationErrors) { [weak self] errors in self?.handle(errors: errors) }
        subscribe(disposeBag, service.tradeData) { [weak self] in self?.handle(tradeData: $0) }
        subscribe(disposeBag, service.swapState) { [weak self] in self?.handle(state: $0) }
    }

    private func executionPrice(item: SwapModule.TradeItem) -> String? {
        guard let price = item.executionPrice else {
            return ValueFormatter.instance.format(coinValue: CoinValue(coin: item.coinIn, value: 0))
        }
        let value = price.isZero ? 0 : 1 / price
        return ValueFormatter
                .instance
                .format(coinValue: CoinValue(coin: item.coinIn, value: value))
                .map {
                    [item.coinOut.code, $0].joined(separator: " = ")
                }
    }

    private func tradeViewItem(item: SwapModule.TradeItem) -> SwapModule.TradeViewItem {
        var priceImpact: Decimal = 0
        var impactLevel = SwapModule.PriceImpactLevel.none

        if let value = item.priceImpact {
            priceImpact = value
            if priceImpact <= 1 {
                impactLevel = .normal
            } else if priceImpact <= 5 {
                impactLevel = .warning
            } else {
                impactLevel = .forbidden
            }
        }
        let impactString = priceImpact.description + "%"

        let coinValue: CoinValue?
        let minMaxTitle: String

        switch item.type {
        case .exactIn:
            minMaxTitle = "swap.minimum_got"
            coinValue = item.minMaxAmount.map { CoinValue(coin: item.coinOut, value: $0) }
        case .exactOut:
            minMaxTitle = "swap.maximum_paid"
            coinValue = item.minMaxAmount.map { CoinValue(coin: item.coinIn, value: $0) }
        }

        let minMaxValue = coinValue.flatMap { ValueFormatter.instance.format(coinValue: $0) }

        return SwapModule.TradeViewItem(
                executionPrice: executionPrice(item: item),
                priceImpact: impactString,
                priceImpactLevel: impactLevel,
                minMaxTitle: minMaxTitle, minMaxAmount: minMaxValue)
    }

}

extension SwapViewModel {

    private func handle(balance: CoinValue?) {
        guard let balance = balance else {
            balanceRelay.accept(nil)
            return
        }

        balanceRelay.accept(ValueFormatter.instance.format(coinValue: balance))
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

    var openApprove: Driver<SwapModule.ApproveData?> {
        openApproveRelay.asDriver(onErrorJustReturn: nil)
    }

    var openProceed: Driver<SwapModule.ProceedData?> {
        openProceedRelay.asDriver(onErrorJustReturn: nil)
    }

    func onTapProceed() {
        openProceedRelay.accept(service.proceedData)
    }

    func onTapApprove() {
        openApproveRelay.accept(service.approveData)
    }

    func didApprove() {
        service.didApprove()
    }

}
