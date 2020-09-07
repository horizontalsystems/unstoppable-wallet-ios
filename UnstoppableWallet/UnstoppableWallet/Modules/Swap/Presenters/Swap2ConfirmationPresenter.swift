import Foundation
import RxSwift
import RxCocoa

class Swap2ConfirmationPresenter {
    static let swapFeeValue: Decimal = 0.003
    private let disposeBag = DisposeBag()

    private let service: SwapService
    private let factory: SwapViewItemFactory

    private var amountDataRelay = BehaviorRelay<SwapModule.ConfirmationAmountViewItem?>(value: nil)
    private var additionalDataRelay = BehaviorRelay<[SwapModule.ConfirmationAdditionalViewItem]>(value: [])

    private var loadingRelay = PublishRelay<()>()
    private var successRelay = PublishRelay<()>()
    private var errorRelay = PublishRelay<Error?>()

    init(service: SwapService, factory: SwapViewItemFactory) {
        self.service = service
        self.factory = factory

        subscribeOnService()
        buildState()
    }

    private func subscribeOnService() {
        subscribe(disposeBag, service.swapStateObservable) { [weak self] in self?.handle(swapState: $0) }
    }

    private func buildState() {
        guard let amountIn = service.amountIn,
              let amountOut = service.amountOut,
              let coinOut = service.coinOut else {
            return
        }
        let payValue = ValueFormatter.instance.format(coinValue: CoinValue(coin: service.coinIn, value: amountIn))
        let getValue = ValueFormatter.instance.format(coinValue: CoinValue(coin: coinOut, value: amountOut))

        let amountData = SwapModule.ConfirmationAmountViewItem(
                payTitle: service.coinIn.title,
                payValue: payValue,
                getTitle: coinOut.title,
                getValue: getValue)

        amountDataRelay.accept(amountData)

        guard let item = service.tradeDataState?.data else {
            return
        }

        var additionalData = [SwapModule.ConfirmationAdditionalViewItem]()

        let minMaxValue = factory.minMaxValue(amount: item.minMaxAmount, coinIn: item.coinIn, coinOut: item.coinOut, type: item.type)
        let minMaxTitle = factory.minMaxTitle(type: item.type, coinOut: item.coinOut)
        additionalData.append(SwapModule.ConfirmationAdditionalViewItem(title: minMaxTitle, value: minMaxValue))

        let price = factory.string(executionPrice: item.executionPrice, coinIn: item.coinIn, coinOut: item.coinOut)
        additionalData.append(SwapModule.ConfirmationAdditionalViewItem(title: "swap.price", value: price))

        let priceImpact = factory.string(impactPrice: item.priceImpact)
        additionalData.append(SwapModule.ConfirmationAdditionalViewItem(title: "swap.price_impact", value: priceImpact))

        let coinValue = CoinValue(coin: service.coinIn, value: amountIn * Swap2ConfirmationPresenter.swapFeeValue)
        let swapFee = ValueFormatter.instance.format(coinValue: coinValue)
        additionalData.append(SwapModule.ConfirmationAdditionalViewItem(title: "swap.fee", value: swapFee))

        additionalData.append(SwapModule.ConfirmationAdditionalViewItem(title: "swap.transactions_speed", value: service.feePriority.title))
        if let feeData = service.feeState?.data {
            let coinValue = ValueFormatter.instance.format(coinValue: feeData.coinAmount)
            let currencyValue = feeData.currencyAmount.flatMap { ValueFormatter.instance.format(currencyValue: $0) }

            let array = [coinValue, currencyValue].compactMap { $0 }
            let feeString = array.joined(separator: " | ")

            additionalData.append(SwapModule.ConfirmationAdditionalViewItem(title: "swap.transaction_fee", value: feeString))
        }

        additionalDataRelay.accept(additionalData)
    }

    private func handle(swapState: DataStatus<Data>?) {
        guard let swapState = swapState else {
            return
        }

        if swapState == .loading {
            loadingRelay.accept(())
        }

        if let error = swapState.error {
            errorRelay.accept(error)
            return
        }

        if swapState.data != nil {
            successRelay.accept(())
        }
    }

}

extension Swap2ConfirmationPresenter {

    var amountData: Driver<SwapModule.ConfirmationAmountViewItem?> {
        amountDataRelay.asDriver()
    }

    var additionalData: Driver<[SwapModule.ConfirmationAdditionalViewItem]> {
        additionalDataRelay.asDriver()
    }

    var isLoading: Driver<()> {
        loadingRelay.asDriver(onErrorJustReturn: ())
    }

    var success: Driver<()> {
        successRelay.asDriver(onErrorJustReturn: ())
    }

    var error: Driver<Error?> {
        errorRelay.asDriver(onErrorJustReturn: nil)
    }

}
