import EvmKit
import MarketKit
import UIKit

enum WCSignEthereumTransactionRequestModule {
    static func viewController(request: WalletConnectRequest) -> UIViewController? {
        guard let payload = request.payload as? WCSignEthereumTransactionPayload,
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

        let wcService = App.shared.walletConnectSessionManager.service
        let viewModel = WCSignEthereumTransactionRequestViewModel(requestId: request.id, payload: payload, evmKitWrapper: evmKitWrapper, wcService: wcService)

        let info = SendEvmData.DAppInfo(name: request.payload.dAppName, chainName: request.chain.chainName, address: request.chain.address)
        let additionalInfo: SendEvmData.AdditionInfo = .otherDApp(info: info)
        let sendEvmData = SendEvmData(transactionData: viewModel.transactionData, additionalInfo: additionalInfo, warnings: [])

        guard let (settingsService, settingsViewModel) = EvmSendSettingsModule.instance(
            evmKit: evmKitWrapper.evmKit, blockchainType: evmKitWrapper.blockchainType, sendData: sendEvmData, coinServiceFactory: coinServiceFactory,
            gasPrice: viewModel.gasPrice, predefinedGasLimit: payload.transaction.gasLimit, predefinedNonce: payload.transaction.nonce
        ) else {
            return nil
        }

        let sendService = SendEvmTransactionService(sendData: sendEvmData, evmKitWrapper: evmKitWrapper, settingsService: settingsService, evmLabelManager: App.shared.evmLabelManager)
        let contactLabelService = ContactLabelService(contactManager: App.shared.contactManager, blockchainType: evmKitWrapper.blockchainType)
        let transactionViewModel = SendEvmTransactionViewModel(service: sendService, coinServiceFactory: coinServiceFactory, cautionsFactory: SendEvmCautionsFactory(), evmLabelManager: App.shared.evmLabelManager, contactLabelService: contactLabelService)

        return WCSignEthereumTransactionRequestViewController(viewModel: viewModel, transactionViewModel: transactionViewModel, settingsViewModel: settingsViewModel)
    }
}
