import Foundation
import EthereumKit
import ThemeKit
import BigInt

struct SwapApproveModule {

    static func instance(data: SwapAllowanceService.ApproveData, delegate: ISwapApproveDelegate) -> UIViewController? {
        guard let ethereumKit = App.shared.ethereumKitManager.ethereumKit,
              let wallet = App.shared.walletManager.wallets.first(where: { $0.coin == data.coin }),
              let erc20Adapter = App.shared.adapterManager.adapter(for: wallet) as? Erc20Adapter else {

            return nil
        }

        let coinService = CoinService(
                coin: data.coin,
                currencyKit: App.shared.currencyKit,
                rateManager: App.shared.rateManager
        )

        let ethereumCoinService = CoinService(
                coin: App.shared.appConfigProvider.ethereumCoin,
                currencyKit: App.shared.currencyKit,
                rateManager: App.shared.rateManager
        )

        let transactionService = EthereumTransactionService(
                ethereumKit: ethereumKit,
                feeRateProvider: App.shared.feeRateProviderFactory.provider(coinType: .ethereum) as! EthereumFeeRateProvider
        )

        let service = SwapApproveService(
                transactionService: transactionService,
                erc20Kit: erc20Adapter.erc20Kit,
                ethereumKit: ethereumKit,
                amount: BigUInt(data.amount.roundedString(decimal: data.coin.decimal)) ?? 0,
                spenderAddress: data.spenderAddress,
                allowance: BigUInt(data.allowance.roundedString(decimal: data.coin.decimal)) ?? 0
        )

        let decimalParser = AmountDecimalParser()
        let feeViewModel = EthereumFeeViewModel(service: transactionService, coinService: ethereumCoinService)
        let viewModel = SwapApproveViewModel(service: service, coinService: coinService, ethereumCoinService: ethereumCoinService, decimalParser: decimalParser)
        let viewController = SwapApproveViewController(
                viewModel: viewModel,
                feeViewModel: feeViewModel,
                delegate: delegate
        )

        return ThemeNavigationController(rootViewController: viewController)
    }

}

protocol ISwapApproveDelegate {
    func didApprove()
}
