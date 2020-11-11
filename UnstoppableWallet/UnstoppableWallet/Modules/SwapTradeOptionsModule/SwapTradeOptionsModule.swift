import UIKit
import ThemeKit

struct SwapTradeOptionsModule {

    static func viewController(tradeService: SwapTradeService) -> UIViewController {
        let service = SwapTradeOptionsService(tradeOptions: tradeService.tradeOptions)
        let viewModel = SwapTradeOptionsViewModel(service: service, tradeService: tradeService, decimalParser: AmountDecimalParser())
        let viewController = SwapTradeOptionsView(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}
