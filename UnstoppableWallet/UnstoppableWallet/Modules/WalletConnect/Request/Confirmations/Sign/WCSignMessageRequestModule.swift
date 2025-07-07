import EvmKit
import SwiftUI
import UIKit

enum WCSignMessageRequestModule {
    static func viewController(request: WalletConnectRequest) -> UIViewController? {
        guard let account = Core.shared.accountManager.activeAccount,
              let evmWrapper = Core.shared.evmBlockchainManager.kitWrapper(chainId: request.chain.id, account: account),
              let signer = evmWrapper.signer
        else {
            return nil
        }

        return viewController(account: account, evmWrapper: evmWrapper, signer: signer, request: request)
    }

    static func viewController(account _: Account, evmWrapper _: EvmKitWrapper, signer: Signer, request: WalletConnectRequest) -> UIViewController {
        let signService = Core.shared.walletConnectSessionManager.service
        let service = WCSignMessageRequestService(request: request, signService: signService, signer: signer)
        let viewModel = WCSignMessageRequestViewModel(service: service)

        return WCSignMessageRequestViewController(viewModel: viewModel)
    }
}

struct WCSignMessageRequestView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    let request: WalletConnectRequest

    init(request: WalletConnectRequest) {
        self.request = request
    }

    func makeUIViewController(context _: Context) -> UIViewController {
        let controller = WCSignMessageRequestModule.viewController(request: request) ??
            ErrorViewController(text: AppError.unknownError.localizedDescription)

        return ThemeNavigationController(rootViewController: controller)
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
