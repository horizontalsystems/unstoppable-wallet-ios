import EvmKit
import MarketKit
import UIKit

enum WCSendEthereumTransactionRequestModule {
    static func viewController(request: WalletConnectRequest) -> UIViewController? {
        guard let payload = request.payload as? WCEthereumTransactionPayload,
              let account = App.shared.accountManager.activeAccount,
              let evmKitWrapper = App.shared.walletConnectManager.evmKitWrapper(chainId: request.chain.id, account: account)
        else {
            return nil
        }

        guard let coinServiceFactory = EvmCoinServiceFactory(
            blockchainType: evmKitWrapper.blockchainType,
            marketKit: App.shared.marketKit,
            currencyManager: App.shared.currencyManager,
            coinManager: App.shared.coinManager
        ) else {
            return nil
        }

        let signService = App.shared.walletConnectSessionManager.service
        guard let service = WCSendEthereumTransactionRequestService(request: request, baseService: signService) else {
            return nil
        }
        let info = SendEvmData.DAppInfo(name: request.payload.dAppName, chainName: request.chain.chainName, address: request.chain.address)
        let additionalInfo: SendEvmData.AdditionInfo = .otherDApp(info: info)
        let sendEvmData = SendEvmData(transactionData: service.transactionData, additionalInfo: additionalInfo, warnings: [])

        guard let (settingsService, settingsViewModel) = EvmSendSettingsModule.instance(
            evmKit: evmKitWrapper.evmKit, blockchainType: evmKitWrapper.blockchainType, sendData: sendEvmData, coinServiceFactory: coinServiceFactory,
            gasPrice: service.gasPrice, predefinedGasLimit: payload.transaction.gasLimit
        ) else {
            return nil
        }

        let sendService = SendEvmTransactionService(sendData: sendEvmData, evmKitWrapper: evmKitWrapper, settingsService: settingsService, evmLabelManager: App.shared.evmLabelManager)
        let contactLabelService = ContactLabelService(contactManager: App.shared.contactManager, blockchainType: evmKitWrapper.blockchainType)
        let transactionViewModel = SendEvmTransactionViewModel(service: sendService, coinServiceFactory: coinServiceFactory, cautionsFactory: SendEvmCautionsFactory(), evmLabelManager: App.shared.evmLabelManager, contactLabelService: contactLabelService)
        let viewModel = WCSendEthereumTransactionRequestViewModel(service: service)

        return WCSendEthereumTransactionRequestViewController(viewModel: viewModel, transactionViewModel: transactionViewModel, settingsViewModel: settingsViewModel)
    }
}
