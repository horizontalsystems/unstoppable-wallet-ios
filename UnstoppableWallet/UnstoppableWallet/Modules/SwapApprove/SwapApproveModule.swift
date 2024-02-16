import BigInt
import EvmKit
import HsExtensions
import ThemeKit
import UIKit

enum SwapApproveModule {
    static func instance(data: SwapAllowanceService.ApproveData, delegate: ISwapApproveDelegate) -> UIViewController? {
        guard let eip20Adapter = App.shared.adapterManager.adapter(for: data.token) as? Eip20Adapter else {
            return nil
        }

        let coinService = CoinService(
            token: data.token,
            currencyManager: App.shared.currencyManager,
            marketKit: App.shared.marketKit
        )

        let service = SwapApproveService(
            eip20Kit: eip20Adapter.eip20Kit,
            amount: BigUInt(data.amount.hs.roundedString(decimal: data.token.decimals)) ?? 0,
            spenderAddress: data.spenderAddress,
            allowance: BigUInt(data.allowance.hs.roundedString(decimal: data.token.decimals)) ?? 0
        )

        let decimalParser = AmountDecimalParser()
        let viewModel = SwapApproveViewModel(service: service, coinService: coinService, decimalParser: decimalParser)
        let viewController = SwapApproveViewController(
            viewModel: viewModel,
            delegate: delegate,
            dex: data.dex
        )

        return ThemeNavigationController(rootViewController: viewController)
    }
}

protocol ISwapApproveDelegate: AnyObject {
    func didApprove()
}
