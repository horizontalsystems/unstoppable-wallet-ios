import UIKit
import EthereumKit
import CoinKit

struct WalletConnectSignMessageRequestModule {

    static func viewController(baseService: WalletConnectService, requestId: Int) -> UIViewController? {
        guard let request = baseService.pendingRequest(requestId: requestId) as? WalletConnectSignMessageRequest else {
            return nil
        }

        let service = WalletConnectSignMessageRequestService(request: request, baseService: baseService)
        let viewModel = WalletConnectSignMessageRequestViewModel(service: service)

        return WalletConnectSignMessageRequestViewController(viewModel: viewModel)
    }

}
