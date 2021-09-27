import UIKit
import EthereumKit

struct WalletConnectSignMessageRequestModule {

    static func viewController(baseService: WalletConnectService, requestId: Int) -> UIViewController? {
        guard let request = baseService.pendingRequest(requestId: requestId) as? WalletConnectSignMessageRequest else {
            return nil
        }
        guard let evmKit = baseService.evmKit else {
            return nil
        }

        let service = WalletConnectSignMessageRequestService(request: request, baseService: baseService, evmKit: evmKit)
        let viewModel = WalletConnectSignMessageRequestViewModel(service: service)

        return WalletConnectSignMessageRequestViewController(viewModel: viewModel)
    }

}
