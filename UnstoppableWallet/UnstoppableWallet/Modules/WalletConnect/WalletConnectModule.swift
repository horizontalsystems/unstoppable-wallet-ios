import UIKit
import ThemeKit

struct WalletConnectModule {

    static func start(sourceViewController: UIViewController?) {
        Self.internalStart(sourceViewController: sourceViewController)
    }

    static func start(session: WalletConnectSession, sourceViewController: UIViewController?) {
        Self.internalStart(session: session, sourceViewController: sourceViewController)
    }

    static func start(uri: String, sourceViewController: UIViewController?) {
        Self.internalStart(uri: uri, sourceViewController: sourceViewController)
    }

    private static func internalStart(session: WalletConnectSession? = nil, uri: String? = nil, sourceViewController: UIViewController?) {
//        let openScanQrController = session == nil && uri == nil
//
//        let viewController: UIViewController
//        if openScanQrController {
//            let viewModel = WalletConnectScanQrViewModel()
//            viewController = WalletConnectScanQrViewController(viewModel: viewModel, sourceViewController: sourceViewController)
//        } else {
//            let service = WalletConnectService(
//                    session: session,
//                    uri: uri,
//                    manager: App.shared.walletConnectManager,
//                    sessionManager: App.shared.walletConnectSessionManager,
//                    reachabilityManager: App.shared.reachabilityManager
//            )
//            let moduleFactory = WalletConnectMainFactory(service: service)
//            viewController = ThemeNavigationController(rootViewController: WalletConnectMainViewController(moduleFactory: moduleFactory, sourceViewController: sourceViewController))
//        }
//
//        sourceViewController?.present(viewController, animated: true)
    }

}
