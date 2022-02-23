import UIKit
import EthereumKit
import MarketKit

struct WalletConnectSendEthereumTransactionRequestModule {

    static func viewController(signService: WalletConnectV1XMainService, requestId: Int) -> UIViewController? {
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

        guard let platformCoin = App.shared.evmBlockchainManager.basePlatformCoin(blockchain: evmKitWrapper.blockchain) else {
            return nil
        }

        let service = WalletConnectSendEthereumTransactionRequestService(request: request, baseService: signService)
        let coinServiceFactory = EvmCoinServiceFactory(basePlatformCoin: platformCoin, marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit)
        let gasPriceService = EvmFeeModule.gasPriceService(evmKit: evmKitWrapper.evmKit, gasPrice: service.gasPrice.flatMap { GasPrice.legacy(gasPrice: $0) }) // TODO: walletConnect service must pass GasPrice object
        let feeService = EvmFeeService(evmKit: evmKitWrapper.evmKit, gasPriceService: gasPriceService, transactionData: service.transactionData, gasLimitSurchargePercent: 10)
        let sendEvmData = SendEvmData(transactionData: service.transactionData, additionalInfo: nil, warnings: [])
        let sendService = SendEvmTransactionService(sendData: sendEvmData, evmKitWrapper: evmKitWrapper, feeService: feeService, activateCoinManager: App.shared.activateCoinManager)

        let transactionViewModel = SendEvmTransactionViewModel(service: sendService, coinServiceFactory: coinServiceFactory, cautionsFactory: SendEvmCautionsFactory())
        let feeViewModel = EvmFeeViewModel(service: feeService, gasPriceService: gasPriceService, coinService: coinServiceFactory.baseCoinService)
        let viewModel = WalletConnectSendEthereumTransactionRequestViewModel(service: service)

        return WalletConnectRequestViewController(viewModel: viewModel, transactionViewModel: transactionViewModel, feeViewModel: feeViewModel)
    }

}
