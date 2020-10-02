import UIKit

class WalletConnectMainModule {

    static func viewController(baseView: WalletConnectView) -> UIViewController? {
        guard let client = baseView.viewModel.service.client, let ethereumKit = baseView.viewModel.service.ethereumKit else {
            return nil
        }

        let service = WalletConnectMainService(client: client, ethereumKit: ethereumKit)
        let viewModel = WalletConnectMainViewModel(service: service)

        client.interactor.delegate = service

        return WalletConnectMainViewController(baseView: baseView, viewModel: viewModel)
    }

}
