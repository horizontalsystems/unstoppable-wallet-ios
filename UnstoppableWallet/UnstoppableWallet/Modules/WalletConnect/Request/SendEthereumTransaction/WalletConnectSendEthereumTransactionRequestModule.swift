import UIKit
import EthereumKit
import MarketKit

struct WalletConnectSendEthereumTransactionRequestModule {

    static func viewController(baseService: WalletConnectV1XMainService, requestId: Int) -> UIViewController? {
        guard let request = baseService.pendingRequest(requestId: requestId) as? WalletConnectSendEthereumTransactionRequest, let evmKitWrapper = baseService.evmKitWrapper else {
            return nil
        }

        let feePlatformCoin: PlatformCoin?

        switch evmKitWrapper.evmKit.networkType {
        case .ethMainNet, .ropsten, .rinkeby, .kovan, .goerli: feePlatformCoin = try? App.shared.marketKit.platformCoin(coinType: .ethereum)
        case .bscMainNet: feePlatformCoin = try? App.shared.marketKit.platformCoin(coinType: .binanceSmartChain)
        }

        guard let platformCoin = feePlatformCoin, let feeRateProvider = App.shared.feeRateProviderFactory.provider(coinType: platformCoin.coinType) as? ICustomRangedFeeRateProvider else {
            return nil
        }

        let service = WalletConnectSendEthereumTransactionRequestService(request: request, baseService: baseService)
        let coinServiceFactory = EvmCoinServiceFactory(basePlatformCoin: platformCoin, marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit)
        let gasPriceService = LegacyGasPriceService(evmKit: evmKitWrapper.evmKit, feeRateProvider: feeRateProvider, gasPrice: service.gasPrice)
        let feeService = EvmFeeService(evmKit: evmKitWrapper.evmKit, gasPriceService: gasPriceService, transactionData: service.transactionData, gasLimitSurchargePercent: 10)
        let sendEvmData = SendEvmData(transactionData: service.transactionData, additionalInfo: nil, warnings: [])
        let sendService = SendEvmTransactionService(sendData: sendEvmData, evmKitWrapper: evmKitWrapper, feeService: feeService, activateCoinManager: App.shared.activateCoinManager)

        let transactionViewModel = SendEvmTransactionViewModel(service: sendService, coinServiceFactory: coinServiceFactory, cautionsFactory: SendEvmCautionsFactory())
        let feeViewModel = EvmFeeViewModel(service: feeService, coinService: coinServiceFactory.baseCoinService)
        let viewModel = WalletConnectSendEthereumTransactionRequestViewModel(service: service)

        return WalletConnectRequestViewController(viewModel: viewModel, transactionViewModel: transactionViewModel, feeViewModel: feeViewModel)
    }

}
