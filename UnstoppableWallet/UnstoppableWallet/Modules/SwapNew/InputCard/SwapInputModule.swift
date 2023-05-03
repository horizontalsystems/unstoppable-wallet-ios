import Foundation

class SwapInputModule {

    static func cell(service: UniswapService, tradeService: UniswapTradeService, switchService: AmountTypeSwitchService) -> SwapInputCell {
        let fromCoinCardService = SwapFromCoinCardService(service: service, tradeService: tradeService)
        let toCoinCardService = SwapToCoinCardService(service: service, tradeService: tradeService)

        let fromFiatService = FiatService(switchService: switchService, currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)
        let toFiatService = FiatService(switchService: switchService, currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)
        switchService.add(toggleAllowedObservable: fromFiatService.toggleAvailableObservable)
        switchService.add(toggleAllowedObservable: toFiatService.toggleAvailableObservable)

        let fromViewModel = SwapCoinCardViewModel(coinCardService: fromCoinCardService, fiatService: fromFiatService)
        let toViewModel = SwapCoinCardViewModel(coinCardService: toCoinCardService, fiatService: toFiatService)

        let fromAmountInputViewModel = AmountInputViewModel(
                service: fromCoinCardService,
                fiatService: fromFiatService,
                switchService: switchService,
                decimalParser: AmountDecimalParser()
        )
        let toAmountInputViewModel = AmountInputViewModel(
                service: toCoinCardService,
                fiatService: toFiatService,
                switchService: switchService,
                decimalParser: AmountDecimalParser()
        )

        return SwapInputCell(fromViewModel: fromViewModel,
                fromAmountInputViewModel: fromAmountInputViewModel,
                toViewModel: toViewModel,
                toAmountInputViewModel: toAmountInputViewModel
        )
    }

    static func cell(service: UniswapV3Service, tradeService: UniswapV3TradeService, switchService: AmountTypeSwitchService) -> SwapInputCell {
        let fromCoinCardService = SwapV3FromCoinCardService(service: service, tradeService: tradeService)
        let toCoinCardService = SwapV3ToCoinCardService(service: service, tradeService: tradeService)

        let fromFiatService = FiatService(switchService: switchService, currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)
        let toFiatService = FiatService(switchService: switchService, currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)
        switchService.add(toggleAllowedObservable: fromFiatService.toggleAvailableObservable)
        switchService.add(toggleAllowedObservable: toFiatService.toggleAvailableObservable)

        let fromViewModel = SwapCoinCardViewModel(coinCardService: fromCoinCardService, fiatService: fromFiatService)
        let toViewModel = SwapCoinCardViewModel(coinCardService: toCoinCardService, fiatService: toFiatService)

        let fromAmountInputViewModel = AmountInputViewModel(
                service: fromCoinCardService,
                fiatService: fromFiatService,
                switchService: switchService,
                decimalParser: AmountDecimalParser()
        )
        let toAmountInputViewModel = AmountInputViewModel(
                service: toCoinCardService,
                fiatService: toFiatService,
                switchService: switchService,
                decimalParser: AmountDecimalParser()
        )

        return SwapInputCell(fromViewModel: fromViewModel,
                fromAmountInputViewModel: fromAmountInputViewModel,
                toViewModel: toViewModel,
                toAmountInputViewModel: toAmountInputViewModel
        )
    }

    static func cell(service: OneInchService, tradeService: OneInchTradeService, switchService: AmountTypeSwitchService) -> SwapInputCell {
        let fromCoinCardService = SwapFromCoinCardOneInchService(service: service, tradeService: tradeService)
        let toCoinCardService = SwapToCoinCardOneInchService(service: service, tradeService: tradeService)

        let fromFiatService = FiatService(switchService: switchService, currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)
        let toFiatService = FiatService(switchService: switchService, currencyKit: App.shared.currencyKit, marketKit: App.shared.marketKit)
        switchService.add(toggleAllowedObservable: fromFiatService.toggleAvailableObservable)
        switchService.add(toggleAllowedObservable: toFiatService.toggleAvailableObservable)

        let fromViewModel = SwapCoinCardViewModel(coinCardService: fromCoinCardService, fiatService: fromFiatService)
        let toViewModel = SwapCoinCardViewModel(coinCardService: toCoinCardService, fiatService: toFiatService)

        let fromAmountInputViewModel = AmountInputViewModel(
                service: fromCoinCardService,
                fiatService: fromFiatService,
                switchService: switchService,
                decimalParser: AmountDecimalParser()
        )
        let toAmountInputViewModel = AmountInputViewModel(
                service: toCoinCardService,
                fiatService: toFiatService,
                switchService: switchService,
                decimalParser: AmountDecimalParser()
        )

        return SwapInputCell(fromViewModel: fromViewModel,
                fromAmountInputViewModel: fromAmountInputViewModel,
                toViewModel: toViewModel,
                toAmountInputViewModel: toAmountInputViewModel
        )
    }

}
