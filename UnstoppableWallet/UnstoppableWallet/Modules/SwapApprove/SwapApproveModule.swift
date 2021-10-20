import Foundation
import EthereumKit
import ThemeKit
import BigInt

struct SwapApproveModule {

    static func instance(data: SwapAllowanceService.ApproveData, delegate: ISwapApproveDelegate) -> UIViewController? {
        guard let evm20Adapter = App.shared.adapterManager.adapter(for: data.platformCoin) as? Evm20Adapter else {
            return nil
        }

        let coinService = CoinService(
                platformCoin: data.platformCoin,
                currencyKit: App.shared.currencyKit,
                marketKit: App.shared.marketKit
        )

        let service = SwapApproveService(
                erc20Kit: evm20Adapter.evm20Kit,
                amount: BigUInt(data.amount.roundedString(decimal: data.platformCoin.decimals)) ?? 0,
                spenderAddress: data.spenderAddress,
                allowance: BigUInt(data.allowance.roundedString(decimal: data.platformCoin.decimals)) ?? 0
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
