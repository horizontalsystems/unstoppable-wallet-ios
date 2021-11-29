import UIKit
import EthereumKit
import MarketKit

struct WalletConnectSendEthereumTransactionRequestModule {

    static func viewController(baseService: WalletConnectService, requestId: Int) -> UIViewController? {
        guard let request = baseService.pendingRequest(requestId: requestId) as? WalletConnectSendEthereumTransactionRequest, let evmKit = baseService.evmKit else {
            return nil
        }

        let feePlatformCoin: PlatformCoin?

        switch evmKit.networkType {
        case .ethMainNet, .ropsten, .rinkeby, .kovan, .goerli: feePlatformCoin = try? App.shared.marketKit.platformCoin(coinType: .ethereum)
        case .bscMainNet: feePlatformCoin = try? App.shared.marketKit.platformCoin(coinType: .binanceSmartChain)
        }

        guard let platformCoin = feePlatformCoin, let feeRateProvider = App.shared.feeRateProviderFactory.provider(coinType: platformCoin.coinType) as? ICustomRangedFeeRateProvider else {
            return nil
        }

        let service = WalletConnectSendEthereumTransactionRequestService(request: request, baseService: baseService)
        let coinServiceFactory = EvmCoinServiceFactory(basePlatformCoin: platformCoin, marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit)
        let transactionService = EvmTransactionService(evmKit: evmKit, feeRateProvider: feeRateProvider, gasLimitSurchargePercent: 10)
        let sendService = SendEvmTransactionService(sendData: SendEvmData(transactionData: service.transactionData, additionalInfo: nil), gasPrice: service.gasPrice, evmKit: evmKit, transactionService: transactionService, activateCoinManager: App.shared.activateCoinManager)

        let transactionViewModel = SendEvmTransactionViewModel(service: sendService, coinServiceFactory: coinServiceFactory)
        let feeViewModel = EthereumFeeViewModel(service: transactionService, coinService: coinServiceFactory.baseCoinService)
        let viewModel = WalletConnectSendEthereumTransactionRequestViewModel(service: service)

        return WalletConnectRequestViewController(viewModel: viewModel, transactionViewModel: transactionViewModel, feeViewModel: feeViewModel)
    }

}
