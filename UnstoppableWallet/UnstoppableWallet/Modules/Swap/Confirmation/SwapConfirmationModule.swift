import UIKit
import ThemeKit

struct SwapConfirmationModule {

    static func viewController(service: SwapService, tradeService: SwapTradeService, transactionService: EvmTransactionService) -> UIViewController {
        let ethereumCoinService = CoinService(
                coin: service.dex.coin,
                currencyKit: App.shared.currencyKit,
                rateManager: App.shared.rateManager
        )

        let viewModel = SwapConfirmationViewModel(service: service, tradeService: tradeService, transactionService: transactionService, ethereumCoinService: ethereumCoinService, viewItemHelper: SwapViewItemHelper())
        let viewController = SwapConfirmationView(viewModel: viewModel)

        return viewController
    }

}
