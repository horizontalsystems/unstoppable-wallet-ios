import EvmKit
import MarketKit
import SwiftUI
import UIKit

enum WCSignEthereumTransactionRequestModule {
    static func viewController(request: WalletConnectRequest) -> UIViewController? {
        guard let payload = request.payload as? WCSignEthereumTransactionPayload,
              let account = Core.shared.accountManager.activeAccount,
              let evmKitWrapper = Core.shared.evmBlockchainManager.kitWrapper(chainId: request.chain.id, account: account)
        else {
            return nil
        }

        guard let coinServiceFactory = EvmCoinServiceFactory(
            blockchainType: evmKitWrapper.blockchainType,
            marketKit: Core.shared.marketKit,
            currencyManager: Core.shared.currencyManager,
            coinManager: Core.shared.coinManager
        ) else {
            return nil
        }

        let wcService = Core.shared.walletConnectSessionManager.service
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

        let sendService = SendEvmTransactionService(sendData: sendEvmData, evmKitWrapper: evmKitWrapper, settingsService: settingsService, evmLabelManager: Core.shared.evmLabelManager)
        let contactLabelService = ContactLabelService(contactManager: Core.shared.contactManager, blockchainType: evmKitWrapper.blockchainType)
        let transactionViewModel = SendEvmTransactionViewModel(service: sendService, coinServiceFactory: coinServiceFactory, cautionsFactory: SendEvmCautionsFactory(), evmLabelManager: Core.shared.evmLabelManager, contactLabelService: contactLabelService)

        return WCSignEthereumTransactionRequestViewController(viewModel: viewModel, transactionViewModel: transactionViewModel, settingsViewModel: settingsViewModel)
    }
}

struct WCSignEthereumTransactionRequestView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    let request: WalletConnectRequest

    init(request: WalletConnectRequest) {
        self.request = request
    }

    func makeUIViewController(context _: Context) -> UIViewController {
        let controller = WCSignEthereumTransactionRequestModule.viewController(request: request) ??
            ErrorViewController(text: AppError.unknownError.localizedDescription)

        return ThemeNavigationController(rootViewController: controller)
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
