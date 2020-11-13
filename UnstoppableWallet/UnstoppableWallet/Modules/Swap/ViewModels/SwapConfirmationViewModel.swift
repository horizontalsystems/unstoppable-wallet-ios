import Foundation
import RxSwift
import RxCocoa

class SwapConfirmationViewModel {
    private let disposeBag = DisposeBag()

    private let service: SwapServiceNew
    private let tradeService: SwapTradeService
    private let transactionService: EthereumTransactionService
    private let ethereumCoinService: CoinService

    private let viewItemHelper: SwapViewItemHelper

    private var amountDataRelay = BehaviorRelay<SwapModule.ConfirmationAmountViewItem?>(value: nil)
    private var additionalDataRelay = BehaviorRelay<[SwapModule.ConfirmationAdditionalViewItem]>(value: [])

    private var loadingRelay = PublishRelay<()>()
    private var completedRelay = PublishRelay<()>()
    private var errorRelay = PublishRelay<Error>()

    init(service: SwapServiceNew, tradeService: SwapTradeService, transactionService: EthereumTransactionService, ethereumCoinService: CoinService, viewItemHelper: SwapViewItemHelper) {
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

        if let slippage = viewItemHelper.slippage(tradeService.tradeOptions.allowedSlippage) {
            additionalData.append(SwapModule.ConfirmationAdditionalViewItem(title: "swap.advanced_settings.slippage".localized, value: slippage))
        }
        if let deadline = viewItemHelper.deadline(tradeService.tradeOptions.ttl) {
            additionalData.append(SwapModule.ConfirmationAdditionalViewItem(title: "swap.advanced_settings.deadline".localized, value: deadline))
        }
        if let recipient = tradeService.tradeOptions.recipient?.hex {
            additionalData.append(SwapModule.ConfirmationAdditionalViewItem(title: "swap.advanced_settings.recipient_address".localized, value: recipient))
        }

        guard case let .ready(trade) = tradeService.state else {
            return
        }

        let minMaxTitle = viewItemHelper.minMaxTitle(type: trade.tradeData.type)
        if let minMaxValue = viewItemHelper.minMaxValue(amount: trade.minMaxAmount, coinIn: coinIn, coinOut: coinOut, type: trade.tradeData.type) {
            additionalData.append(SwapModule.ConfirmationAdditionalViewItem(title: minMaxTitle, value: minMaxValue.formattedString))
        }

        if let price = viewItemHelper.priceValue(executionPrice: trade.tradeData.executionPrice, coinIn: coinIn, coinOut: coinOut) {
            additionalData.append(SwapModule.ConfirmationAdditionalViewItem(title: "swap.price".localized, value: price.formattedString))
        }

        let priceImpact = viewItemHelper.impactPrice(trade.tradeData.priceImpact)
        additionalData.append(SwapModule.ConfirmationAdditionalViewItem(title: "swap.price_impact".localized, value: priceImpact))

        if let transaction = transactionService.transactionStatus.data {
            let fee = ethereumCoinService.amountData(value: transaction.gasData.fee).formattedString
            additionalData.append(SwapModule.ConfirmationAdditionalViewItem(title: "swap.fee".localized, value: fee))
        }

        additionalDataRelay.accept(additionalData)
    }

    private func sync(event: SwapServiceNew.SwapEvent) {
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
