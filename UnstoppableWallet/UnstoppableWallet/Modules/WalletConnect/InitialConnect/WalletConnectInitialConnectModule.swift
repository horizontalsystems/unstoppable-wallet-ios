import UIKit

class WalletConnectInitialConnectModule {

    static func viewController(baseView: WalletConnectView) -> UIViewController? {
        guard let interactor = baseView.viewModel.service.interactor, let ethereumKit = baseView.viewModel.service.ethereumKit else {
            return nil
        }

        let service = WalletConnectInitialConnectService(interactor: interactor, ethereumKit: ethereumKit)
        let viewModel = WalletConnectInitialConnectViewModel(service: service)

        interactor.delegate = service

        return WalletConnectInitialConnectViewController(baseView: baseView, viewModel: viewModel)
    }

}
