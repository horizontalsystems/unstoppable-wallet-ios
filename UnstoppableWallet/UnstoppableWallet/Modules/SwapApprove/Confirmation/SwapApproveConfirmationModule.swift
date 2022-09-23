import UIKit
import ThemeKit
import EthereumKit
import BigInt

struct SwapApproveConfirmationModule {

    static func viewController(sendData: SendEvmData, dex: SwapModule.Dex, revokeAllowance: Bool = false, delegate: ISwapApproveDelegate?) -> UIViewController? {
        guard let evmKitWrapper = App.shared.evmBlockchainManager.evmKitManager(blockchainType: dex.blockchainType).evmKitWrapper else {
            return nil
        }

        guard let coinServiceFactory = EvmCoinServiceFactory(blockchainType: dex.blockchainType, marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit) else {
            return nil
        }

        let gasPriceService = EvmFeeModule.gasPriceService(evmKit: evmKitWrapper.evmKit)
        let gasDataService = EvmCommonGasDataService.instance(evmKit: evmKitWrapper.evmKit, blockchainType: evmKitWrapper.blockchainType, gasLimitSurchargePercent: 20)
        let feeService = EvmFeeService(evmKit: evmKitWrapper.evmKit, gasPriceService: gasPriceService, gasDataService: gasDataService, transactionData: sendData.transactionData)
        let service = SendEvmTransactionService(sendData: sendData, evmKitWrapper: evmKitWrapper, feeService: feeService, evmLabelManager: App.shared.evmLabelManager)

        let transactionViewModel = SendEvmTransactionViewModel(service: service, coinServiceFactory: coinServiceFactory, cautionsFactory: SendEvmCautionsFactory(), evmLabelManager: App.shared.evmLabelManager)
        let feeViewModel = EvmFeeViewModel(service: feeService, gasPriceService: gasPriceService, coinService: coinServiceFactory.baseCoinService)

        if revokeAllowance {
            return SwapRevokeConfirmationViewController(transactionViewModel: transactionViewModel, feeViewModel: feeViewModel, delegate: delegate)
        }
        return SwapApproveConfirmationViewController(transactionViewModel: transactionViewModel, feeViewModel: feeViewModel, delegate: delegate)
    }

    static func revokeViewController(data: SwapAllowanceService.ApproveData, delegate: ISwapApproveDelegate) -> UIViewController? {
        guard let evm20Adapter = App.shared.adapterManager.adapter(for: data.token) as? Evm20Adapter else {
            return nil
        }

        let service = SwapApproveService(
                erc20Kit: evm20Adapter.evm20Kit,
                amount: BigUInt(data.amount.roundedString(decimal: data.token.decimals)) ?? 0,
                spenderAddress: data.spenderAddress,
                allowance: 0
        )

        guard case let .approveAllowed(sendData) = service.state else {
            return nil
        }
        let sendEvmData = SendEvmData(transactionData: sendData, additionalInfo: nil, warnings: [])

        guard let confirmationController = SwapApproveConfirmationModule.viewController(sendData: sendEvmData, dex: data.dex, revokeAllowance: true, delegate: delegate) else {
            return nil
        }

        return ThemeNavigationController(rootViewController: confirmationController)
    }


}
