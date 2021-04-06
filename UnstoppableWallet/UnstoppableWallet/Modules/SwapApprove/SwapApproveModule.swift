import Foundation
import EthereumKit
import ThemeKit
import BigInt

struct SwapApproveModule {

    static func instance(data: SwapAllowanceService.ApproveData, delegate: ISwapApproveDelegate) -> UIViewController? {
        guard let wallet = App.shared.walletManager.activeWallets.first(where: { $0.coin == data.coin }),
              let evm20Adapter = App.shared.adapterManager.adapter(for: wallet) as? Evm20Adapter else {
            return nil
        }

        let coinService = CoinService(
                coin: data.coin,
                currencyKit: App.shared.currencyKit,
                rateManager: App.shared.rateManager
        )

        let service = SwapApproveService(
                erc20Kit: evm20Adapter.evm20Kit,
                amount: BigUInt(data.amount.roundedString(decimal: data.coin.decimal)) ?? 0,
                spenderAddress: data.spenderAddress,
                allowance: BigUInt(data.allowance.roundedString(decimal: data.coin.decimal)) ?? 0
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
