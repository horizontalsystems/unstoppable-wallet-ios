import EvmKit
import UIKit

enum WCSignMessageRequestModule {
    static func viewController(request: WalletConnectRequest) -> UIViewController? {
        guard let account = App.shared.accountManager.activeAccount,
              let evmWrapper = App.shared.walletConnectManager.evmKitWrapper(chainId: request.chain.id, account: account),
              let signer = evmWrapper.signer
        else {
            return nil
        }

        let signService = App.shared.walletConnectSessionManager.service
        let service = WCSignMessageRequestService(request: request, signService: signService, signer: signer)
        let viewModel = WCSignMessageRequestViewModel(service: service)

        return WCSignMessageRequestViewController(viewModel: viewModel)
    }
}
