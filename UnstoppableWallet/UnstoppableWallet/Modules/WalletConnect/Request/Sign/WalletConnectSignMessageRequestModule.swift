import UIKit
import EthereumKit

struct WalletConnectSignMessageRequestModule {

    static func viewController(signService: WalletConnectV1MainService, requestId: Int) -> UIViewController? {
        guard let request = signService.pendingRequest(requestId: requestId) as? WalletConnectSignMessageRequest else {
            return nil
        }

        return viewController(signService: signService, request: request)
    }

    static func viewController(signService: IWalletConnectSignService, request: WalletConnectSignMessageRequest) -> UIViewController? {
        guard let account = App.shared.accountManager.activeAccount,
              let evmWrapper = App.shared.walletConnectManager.evmKitWrapper(chainId: request.chainId ?? 1, account: account),
              let signer = evmWrapper.signer else {
            return nil
        }

        let service = WalletConnectSignMessageRequestService(request: request, signService: signService, signer: signer)
        let viewModel = WalletConnectSignMessageRequestViewModel(service: service)

        return WalletConnectSignMessageRequestViewController(viewModel: viewModel)
    }

}
