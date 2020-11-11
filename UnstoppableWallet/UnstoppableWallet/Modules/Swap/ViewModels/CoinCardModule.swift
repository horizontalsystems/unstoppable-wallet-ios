struct CoinCardModule {
    private static var swapCoinService: SwapCoinService {
        SwapCoinService(
                coinManager: App.shared.coinManager,
                walletManager: App.shared.walletManager,
                adapterManager: App.shared.adapterManager
        )
    }

    static func fromCell(service: SwapServiceNew, tradeService: SwapTradeService) -> SwapCoinCardCell {
        let viewModel = SwapFromCoinCardViewModel(service: service, tradeService: tradeService, coinService: swapCoinService, decimalParser: AmountDecimalParser())
        return SwapCoinCardCell(viewModel: viewModel)
    }

    static func toCell(service: SwapServiceNew, tradeService: SwapTradeService) -> SwapCoinCardCell {
        let viewModel = SwapToCoinCardViewModel(service: service, tradeService: tradeService, coinService: swapCoinService, decimalParser: AmountDecimalParser())
        return SwapCoinCardCell(viewModel: viewModel)
    }

}
