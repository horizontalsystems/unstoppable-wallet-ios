import Foundation
import RxSwift
import RxCocoa
import UniswapKit
import CurrencyKit
import EthereumKit

class SwapViewModelNew {
    private let disposeBag = DisposeBag()

    public let service: SwapServiceNew
    public let tradeService: SwapTradeService
    public let transactionService: EthereumTransactionService
    public let pendingAllowanceService: SwapPendingAllowanceService
    private let coinService: CoinService

    public let viewItemHelper: SwapViewItemHelper

    private var isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private var swapErrorRelay = BehaviorRelay<String?>(value: nil)
    private var tradeViewItemRelay = BehaviorRelay<TradeViewItem?>(value: nil)
    private var tradeOptionsViewItemRelay = BehaviorRelay<TradeOptionsViewItem?>(value: nil)
    private var proceedAllowedRelay = BehaviorRelay<Bool>(value: false)
    private var approveActionRelay = BehaviorRelay<ApproveActionState>(value: .hidden)

    private var openApproveRelay = PublishRelay<SwapAllowanceService.ApproveData>()

    init(service: SwapServiceNew, tradeService: SwapTradeService, transactionService: EthereumTransactionService, pendingAllowanceService: SwapPendingAllowanceService, coinService: CoinService, viewItemHelper: SwapViewItemHelper) {
        self.service = service
        self.tradeService = tradeService
        self.transactionService = transactionService
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
        subscribe(disposeBag, tradeService.tradeOptionsObservable) { [weak self] in self?.sync(tradeOptions: $0) }
        subscribe(disposeBag, pendingAllowanceService.isPendingObservable) { [weak self] _ in self?.syncApproveAction() }
    }

    private func sync(state: SwapServiceNew.State? = nil) {
        let state = state ?? service.state

        isLoadingRelay.accept(state == .loading)
        proceedAllowedRelay.accept(state == .ready)
    }

    private func convert(error: Error) -> String {
        if case SwapServiceNew.TransactionError.insufficientBalance(let requiredBalance) = error {
            let amountData = coinService.amountData(value: requiredBalance)
            return "ethereum_transaction.error.insufficient_balance".localized(amountData.formattedString)
        }
        if case EthereumKit.Kit.EstimatedLimitError.insufficientBalance = error {
            return "ethereum_transaction.error.insufficient_balance_with_fee".localized
        }

        return error.convertedError.smartDescription
    }

    private func sync(errors: [Error]? = nil) {
        let errors = errors ?? service.errors

        let filtered = errors.filter { error in
            switch error {
            case let error as UniswapKit.Kit.TradeError: return error != .zeroAmount
            case _ as EthereumTransactionService.GasDataError: return false
            case _ as SwapServiceNew.SwapError: return false
            default: return true
            }
        }

        swapErrorRelay.accept(filtered.first.map { convert(error: $0) })

        syncApproveAction()
    }

    private func sync(tradeState: SwapTradeService.State? = nil) {
        let state = tradeState ?? tradeService.state

        switch state {
        case .ready(let trade):
            tradeViewItemRelay.accept(tradeViewItem(trade: trade))
        default:
            tradeViewItemRelay.accept(nil)
        }
    }

    private func sync(tradeOptions: TradeOptions) {
        tradeOptionsViewItemRelay.accept(tradeOptionsViewItem(tradeOptions: tradeOptions))
    }

    private func syncApproveAction() {
        if pendingAllowanceService.isPending == true {
            approveActionRelay.accept(.pending)
        } else {
            let isInsufficientAllowance = service.errors.contains(where: { .insufficientAllowance == $0 as? SwapServiceNew.SwapError })
            approveActionRelay.accept(isInsufficientAllowance ? .visible : .hidden)
        }
    }

    private func tradeViewItem(trade: SwapTradeService.Trade) -> TradeViewItem {
        TradeViewItem(
                executionPrice: viewItemHelper.priceValue(executionPrice: trade.tradeData.executionPrice, coinIn: tradeService.coinIn, coinOut: tradeService.coinOut)?.formattedString,
                priceImpact: viewItemHelper.impactPrice(trade.tradeData.priceImpact),
                priceImpactLevel: trade.impactLevel,
                minMaxTitle: viewItemHelper.minMaxTitle(type: trade.tradeData.type).localized,
                minMaxAmount: viewItemHelper.minMaxValue(amount: trade.minMaxAmount, coinIn: tradeService.coinIn, coinOut: tradeService.coinOut, type: trade.tradeData.type)?.formattedString
        )
    }

    private func tradeOptionsViewItem(tradeOptions: TradeOptions) -> TradeOptionsViewItem {
        TradeOptionsViewItem(slippage: viewItemHelper.slippage(tradeOptions.allowedSlippage),
            deadline: viewItemHelper.deadline(tradeOptions.ttl),
            recipient: tradeOptions.recipient?.hex)
    }

}

extension SwapViewModelNew {

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

    var proceedAllowedDriver: Driver<Bool> {
        proceedAllowedRelay.asDriver()
    }

    var approveActionDriver: Driver<ApproveActionState> {
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

extension SwapViewModelNew {

    struct TradeViewItem {
        let executionPrice: String?
        let priceImpact: String?
        let priceImpactLevel: SwapTradeService.PriceImpactLevel
        let minMaxTitle: String?
        let minMaxAmount: String?
    }

    struct TradeOptionsViewItem {
        let slippage: String?
        let deadline: String?
        let recipient: String?
    }

    enum ApproveActionState {
        case hidden
        case visible
        case pending
    }

}
