struct CoinCardModule {

    static func fromCell(service: SwapService, tradeService: SwapTradeService) -> SwapCoinCardCell {
        let viewModel = SwapFromCoinCardViewModel(service: service, tradeService: tradeService, decimalParser: AmountDecimalParser())
        return SwapCoinCardCell(viewModel: viewModel)
    }

    static func toCell(service: SwapService, tradeService: SwapTradeService) -> SwapCoinCardCell {
        let viewModel = SwapToCoinCardViewModel(service: service, tradeService: tradeService, decimalParser: AmountDecimalParser())
        return SwapCoinCardCell(viewModel: viewModel)
    }

}
