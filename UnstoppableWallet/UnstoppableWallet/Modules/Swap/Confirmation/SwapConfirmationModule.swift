import UIKit
import ThemeKit

struct SwapConfirmationModule {

    static func viewController(service: SwapService, tradeService: SwapTradeService, transactionService: EvmTransactionService) -> UIViewController? {
        guard let coin = service.dex.coin else {
            return nil
        }

        let ethereumCoinService = CoinService(
                coin: coin,
                currencyKit: App.shared.currencyKit,
                rateManager: App.shared.rateManager
        )

        let viewModel = SwapConfirmationViewModel(service: service, tradeService: tradeService, transactionService: transactionService, ethereumCoinService: ethereumCoinService, viewItemHelper: SwapViewItemHelper())
        let viewController = SwapConfirmationView(viewModel: viewModel)

        return viewController
    }

}
