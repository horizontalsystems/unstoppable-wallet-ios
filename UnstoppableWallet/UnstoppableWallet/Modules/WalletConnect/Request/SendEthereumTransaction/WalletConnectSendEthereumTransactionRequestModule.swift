import UIKit
import EthereumKit
import MarketKit

struct WalletConnectSendEthereumTransactionRequestModule {

    static func viewController(signService: WalletConnectV1MainService, requestId: Int) -> UIViewController? {
        guard let request = signService.pendingRequest(requestId: requestId) as? WalletConnectSendEthereumTransactionRequest else {
            return nil
        }

        return viewController(signService: signService, request: request)
    }

    static func viewController(signService: IWalletConnectSignService, request: WalletConnectSendEthereumTransactionRequest) -> UIViewController? {
        guard let account = App.shared.accountManager.activeAccount,
              let evmKitWrapper = App.shared.walletConnectManager.evmKitWrapper(chainId: request.chainId ?? 1, account: account) else {
            return nil
        }

        guard let coinServiceFactory = EvmCoinServiceFactory(evmBlockchain: evmKitWrapper.blockchain, marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit) else {
            return nil
        }

        let service = WalletConnectSendEthereumTransactionRequestService(request: request, baseService: signService)
        let gasPriceService = EvmFeeModule.gasPriceService(evmKit: evmKitWrapper.evmKit, gasPrice: service.gasPrice)
        let feeService = EvmFeeService(evmKit: evmKitWrapper.evmKit, gasPriceService: gasPriceService, transactionData: service.transactionData, gasLimitSurchargePercent: 10)
        let additionalInfo: SendEvmData.AdditionInfo = .otherDApp(info: SendEvmData.DAppInfo(name: request.dAppName))
        let sendEvmData = SendEvmData(transactionData: service.transactionData, additionalInfo: additionalInfo, warnings: [])
        let sendService = SendEvmTransactionService(sendData: sendEvmData, evmKitWrapper: evmKitWrapper, feeService: feeService, activateCoinManager: App.shared.activateCoinManager)

        let transactionViewModel = SendEvmTransactionViewModel(service: sendService, coinServiceFactory: coinServiceFactory, cautionsFactory: SendEvmCautionsFactory())
        let feeViewModel = EvmFeeViewModel(service: feeService, gasPriceService: gasPriceService, coinService: coinServiceFactory.baseCoinService)
        let viewModel = WalletConnectSendEthereumTransactionRequestViewModel(service: service)

        return WalletConnectRequestViewController(viewModel: viewModel, transactionViewModel: transactionViewModel, feeViewModel: feeViewModel)
    }

}
