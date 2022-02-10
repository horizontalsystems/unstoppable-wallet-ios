import UIKit
import ThemeKit
import RxSwift
import WalletConnect

protocol IWalletConnectXMainService {
    var appMetaItem: WalletConnectXMainModule.AppMetaItem? { get }
    var hint: String? { get }
    var state: WalletConnectXMainModule.State { get }
    var connectionState: WalletConnectXMainModule.ConnectionState { get }

    var stateObservable: Observable<WalletConnectXMainModule.State> { get }
    var connectionStateObservable: Observable<WalletConnectXMainModule.ConnectionState> { get }
    var errorObservable: Observable<Error> { get }

    func reconnect()
    func approveSession()
    func rejectSession()
    func killSession()
}

protocol IWalletConnectXMainRequestView {

}

struct WalletConnectXMainModule {

    static func viewController(session: WalletConnectSession, sourceViewController: UIViewController?) -> UIViewController? {
        let service = WalletConnectV1XMainService(
            session: session,
            manager: App.shared.walletConnectManager,
            sessionManager: App.shared.walletConnectSessionManager,
            reachabilityManager: App.shared.reachabilityManager)

        return viewController(service: service, sourceViewController: sourceViewController)
    }

    static func viewController(session: Session, sourceViewController: UIViewController?) -> UIViewController? {
        let service = App.shared.walletConnectV2SessionManager.service
        let pingService = WalletConnectV2PingService(service: service)

        let mainService = WalletConnectV2XMainService(
            session: session,
            service: service,
            pingService: pingService,
            manager: App.shared.walletConnectManager,
            evmChainParser: WalletConnectEvmChainParser()
        )

        return viewController(service: mainService, sourceViewController: sourceViewController)
    }

    static func viewController(service: IWalletConnectXMainService, sourceViewController: UIViewController?) -> UIViewController? {
        let viewModel = WalletConnectXMainViewModel(service: service)
        let viewController = WalletConnectXMainViewController(viewModel: viewModel, sourceViewController: sourceViewController)
        switch service {
        case let service as WalletConnectV1XMainService:
            let requestViewModel = WalletConnectV1XMainRequestViewModel(service: service)
            let requestView = WalletConnectV1XMainRequestView(viewModel: requestViewModel)
            requestView.sourceViewController = viewController

            viewController.requestView = requestView
        case let service as WalletConnectV2XMainService: ()
        default: return nil
        }

        return ThemeNavigationController(rootViewController: viewController)
    }

}

extension WalletConnectXMainModule {

    struct AppMetaItem {
        let name: String
        let url: String
        let description: String
        let icons: [String]
    }

    enum State: Equatable {
        case idle
        case invalid(error: Error)
        case waitingForApproveSession
        case ready
        case killed

        static func ==(lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle): return true
            case (.invalid(let lhsError), .invalid(let rhsError)): return "\(lhsError)" == "\(rhsError)"
            case (.waitingForApproveSession, .waitingForApproveSession): return true
            case (.ready, .ready): return true
            case (.killed, .killed): return true
            default: return false
            }
        }
    }

    enum ConnectionState {
        case connected
        case connecting
        case disconnected
    }

    enum SessionError: Error {
        case invalidUrl
        case unsupportedChainId
        case noSuitableAccount
    }

}