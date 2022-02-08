import UIKit
import EthereumKit

struct WalletConnectSignMessageRequestModule {

    static func viewController(baseService: WalletConnectV1XMainService, requestId: Int) -> UIViewController? {
        guard let request = baseService.pendingRequest(requestId: requestId) as? WalletConnectSignMessageRequest else {
            return nil
        }
        guard let signer = baseService.evmKitWrapper?.signer else {
            return nil
        }

        let service = WalletConnectSignMessageRequestService(request: request, baseService: baseService, signer: signer)
        let viewModel = WalletConnectSignMessageRequestViewModel(service: service)

        return WalletConnectSignMessageRequestViewController(viewModel: viewModel)
    }

}
