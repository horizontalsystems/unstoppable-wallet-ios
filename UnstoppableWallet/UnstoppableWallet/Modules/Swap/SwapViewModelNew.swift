import Foundation
import RxSwift
import RxCocoa
import UniswapKit
import CurrencyKit

class SwapViewModelNew {
    private let disposeBag = DisposeBag()

    public let service: SwapServiceNew
    public let tradeService: SwapTradeService

    private var isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private var swapErrorRelay = BehaviorRelay<String?>(value: nil)
    private var tradeViewItemRelay = BehaviorRelay<TradeViewItem?>(value: nil)
    private var proceedAllowedRelay = BehaviorRelay<Bool>(value: false)

    init(service: SwapServiceNew, tradeService: SwapTradeService) {
        self.service = service
        self.tradeService = tradeService

        subscribeToService()

        sync(state: service.state)
        sync(errors: service.errors)
        sync(tradeState: tradeService.state)
    }

    private func subscribeToService() {
        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
        subscribe(disposeBag, service.errorsObservable) { [weak self] in self?.sync(errors: $0) }
        subscribe(disposeBag, tradeService.stateObservable) { [weak self] in self?.sync(tradeState: $0) }
    }

    private func sync(state: SwapServiceNew.State? = nil) {
        let state = state ?? service.state

        isLoadingRelay.accept(state == .loading)
        proceedAllowedRelay.accept(state == .ready)
    }

    private func sync(errors: [Error]? = nil) {
        let errors = errors ?? service.errors

        swapErrorRelay.accept(errors.first.map { $0.convertedError.smartDescription })
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

    private func tradeViewItem(trade: SwapTradeService.Trade) -> TradeViewItem {
        TradeViewItem(
                executionPrice: "Ex price",
                priceImpact: "\(trade.tradeData.priceImpact ?? 0)",
                priceImpactLevel: trade.impactLevel,
                minMaxTitle: "MinMaxTitle",
                minMaxAmount: "MinMaxAmount"
        )
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

    var proceedAllowedDriver: Driver<Bool> {
        proceedAllowedRelay.asDriver()
    }

    func onTapSwitch() {
        tradeService.switchCoins()
    }

    func onTapApprove() {
//        openApproveRelay.accept(service.approveData)
    }

    func onTapProceed() {
//        service.proceed()
    }

    func didApprove() {
//        service.didApprove()
    }

    func onSwap() {
//        service.swap()
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

}
