import UIKit
import EvmKit

struct WalletConnectSignMessageRequestModule {

    static func viewController(signService: IWalletConnectSignService, request: WalletConnectSignMessageRequest) -> UIViewController? {
        guard let account = App.shared.accountManager.activeAccount,
              let evmWrapper = App.shared.walletConnectManager.evmKitWrapper(chainId: request.chain.id, account: account),
              let signer = evmWrapper.signer else {
            return nil
        }

        let service = WalletConnectSignMessageRequestService(request: request, signService: signService, signer: signer)
        let viewModel = WalletConnectSignMessageRequestViewModel(service: service)

        return WalletConnectSignMessageRequestViewController(viewModel: viewModel)
    }

}
