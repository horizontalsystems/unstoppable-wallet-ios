import UIKit
import EvmKit
import MarketKit

struct WalletConnectSendEthereumTransactionRequestModule {

    static func viewController(signService: IWalletConnectSignService, request: WalletConnectSendEthereumTransactionRequest) -> UIViewController? {
        guard let account = App.shared.accountManager.activeAccount,
              let evmKitWrapper = App.shared.walletConnectManager.evmKitWrapper(chainId: request.chain.id, account: account) else {
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
        let info = SendEvmData.DAppInfo(name: request.dAppName, chainName: request.chain.chainName, address: request.chain.address)
        let additionalInfo: SendEvmData.AdditionInfo = .otherDApp(info: info)
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
