import UIKit

class WalletConnectInitialConnectModule {

    static func viewController(baseView: WalletConnectView) -> UIViewController? {
        guard let interactor = baseView.viewModel.service.interactor, let ethereumKit = baseView.viewModel.service.ethereumKit else {
            return nil
        }

        let service = WalletConnectInitialConnectService.instance(interactor: interactor, ethereumKit: ethereumKit)
        let viewModel = WalletConnectInitialConnectViewModel(service: service)
        return WalletConnectInitialConnectViewController(baseView: baseView, viewModel: viewModel)
    }

}
