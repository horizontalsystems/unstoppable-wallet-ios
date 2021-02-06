import Foundation
import RxSwift
import RxCocoa

class SwapConfirmationViewModel {
    private let disposeBag = DisposeBag()

    private let service: SwapService
    private let tradeService: SwapTradeService
    private let transactionService: EthereumTransactionService
    private let ethereumCoinService: CoinService

    private let viewItemHelper: SwapViewItemHelper

    private var amountDataRelay = BehaviorRelay<SwapModule.ConfirmationAmountViewItem?>(value: nil)
    private var additionalDataRelay = BehaviorRelay<[SwapModule.ConfirmationAdditionalViewItem]>(value: [])

    private var loadingRelay = PublishRelay<()>()
    private var completedRelay = PublishRelay<()>()
    private var errorRelay = PublishRelay<Error>()

    init(service: SwapService, tradeService: SwapTradeService, transactionService: EthereumTransactionService, ethereumCoinService: CoinService, viewItemHelper: SwapViewItemHelper) {
        self.service = service
        self.tradeService = tradeService
        self.viewItemHelper = viewItemHelper
        self.transactionService = transactionService
        self.ethereumCoinService = ethereumCoinService

        subscribeOnService()
        buildViewItems()
    }

    private func subscribeOnService() {
        subscribe(disposeBag, service.swapEventObservable) { [weak self] in self?.sync(event: $0) }
    }

    private func buildViewItems() {
        guard let coinIn = tradeService.coinIn,
              let amountIn = tradeService.amountIn,
              let amountOut = tradeService.amountOut,
              let coinOut = tradeService.coinOut else {
            return
        }
        let payValue = ValueFormatter.instance.format(coinValue: CoinValue(coin: coinIn, value: amountIn))
        let getValue = ValueFormatter.instance.format(coinValue: CoinValue(coin: coinOut, value: amountOut))

        let amountData = SwapModule.ConfirmationAmountViewItem(
                payTitle: coinIn.title,
                payValue: payValue,
                getTitle: coinOut.title,
                getValue: getValue)

        amountDataRelay.accept(amountData)

        var additionalData = [SwapModule.ConfirmationAdditionalViewItem]()

        if let slippage = viewItemHelper.slippage(tradeService.swapTradeOptions.allowedSlippage) {
            additionalData.append(SwapModule.ConfirmationAdditionalViewItem(title: "swap.advanced_settings.slippage".localized, value: slippage))
        }
        if let deadline = viewItemHelper.deadline(tradeService.swapTradeOptions.ttl) {
            additionalData.append(SwapModule.ConfirmationAdditionalViewItem(title: "swap.advanced_settings.deadline".localized, value: deadline))
        }
        if let recipient = tradeService.swapTradeOptions.recipient?.title {
            additionalData.append(SwapModule.ConfirmationAdditionalViewItem(title: "swap.advanced_settings.recipient_address".localized, value: recipient))
        }

        guard case let .ready(trade) = tradeService.state else {
            return
        }

        if let viewItem = viewItemHelper.guaranteedAmountViewItem(tradeData: trade.tradeData, coinIn: coinIn, coinOut: coinOut) {
            additionalData.append(SwapModule.ConfirmationAdditionalViewItem(title: viewItem.title, value: viewItem.value))
        }

        if let price = viewItemHelper.priceValue(executionPrice: trade.tradeData.executionPrice, coinIn: coinIn, coinOut: coinOut) {
            additionalData.append(SwapModule.ConfirmationAdditionalViewItem(title: "swap.price".localized, value: price.formattedString))
        }

        if let viewItem = viewItemHelper.priceImpactViewItem(trade: trade) {
            additionalData.append(SwapModule.ConfirmationAdditionalViewItem(title: "swap.price_impact".localized, value: viewItem.value))
        }

        if let transaction = transactionService.transactionStatus.data {
            let estimatedFee = ethereumCoinService.amountData(value: transaction.gasData.estimatedFee).formattedString
            additionalData.append(SwapModule.ConfirmationAdditionalViewItem(title: "send.estimated_fee".localized, value: estimatedFee))

            let maxFee = ethereumCoinService.amountData(value: transaction.gasData.fee).formattedString
            additionalData.append(SwapModule.ConfirmationAdditionalViewItem(title: "send.max_fee".localized, value: maxFee))
        }

        additionalDataRelay.accept(additionalData)
    }

    private func sync(event: SwapService.SwapEvent) {
        switch event {
        case .swapping: loadingRelay.accept(())
        case .completed: completedRelay.accept(())
        case .failed(let error): errorRelay.accept(error)
        }
    }

}

extension SwapConfirmationViewModel {

    var amountData: Driver<SwapModule.ConfirmationAmountViewItem?> {
        amountDataRelay.asDriver()
    }

    var additionalData: Driver<[SwapModule.ConfirmationAdditionalViewItem]> {
        additionalDataRelay.asDriver()
    }

    var loadingSignal: Signal<()> {
        loadingRelay.asSignal()
    }

    var completedSignal: Signal<()> {
        completedRelay.asSignal()
    }

    var errorSignal: Signal<Error> {
        errorRelay.asSignal()
    }

    func swap() {
        service.swap()
    }

}
