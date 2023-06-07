import UIKit
import EvmKit
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

        guard let coinServiceFactory = EvmCoinServiceFactory(
                blockchainType: evmKitWrapper.blockchainType,
                marketKit: App.shared.marketKit,
                currencyKit: App.shared.currencyKit,
                coinManager: App.shared.coinManager
        ) else {
            return nil
        }

        let service = WalletConnectSendEthereumTransactionRequestService(request: request, baseService: signService)
        let additionalInfo: SendEvmData.AdditionInfo = .otherDApp(info: SendEvmData.DAppInfo(name: request.dAppName))
        let sendEvmData = SendEvmData(transactionData: service.transactionData, additionalInfo: additionalInfo, warnings: [])

        guard let (settingsService, settingsViewModel) = EvmSendSettingsModule.instance(
                evmKit: evmKitWrapper.evmKit, blockchainType: evmKitWrapper.blockchainType, sendData: sendEvmData, coinServiceFactory: coinServiceFactory,
                gasPrice: service.gasPrice, predefinedGasLimit: request.transaction.gasLimit
        ) else {
            return nil
        }

        let sendService = SendEvmTransactionService(sendData: sendEvmData, evmKitWrapper: evmKitWrapper, settingsService: settingsService, evmLabelManager: App.shared.evmLabelManager)
        let contactLabelService = ContactLabelService(contactManager: App.shared.contactManager, blockchainType: evmKitWrapper.blockchainType)
        let transactionViewModel = SendEvmTransactionViewModel(service: sendService, coinServiceFactory: coinServiceFactory, cautionsFactory: SendEvmCautionsFactory(), evmLabelManager: App.shared.evmLabelManager, contactLabelService: contactLabelService)
        let viewModel = WalletConnectSendEthereumTransactionRequestViewModel(service: service)

        return WalletConnectRequestViewController(viewModel: viewModel, transactionViewModel: transactionViewModel, settingsViewModel: settingsViewModel)
    }

}
