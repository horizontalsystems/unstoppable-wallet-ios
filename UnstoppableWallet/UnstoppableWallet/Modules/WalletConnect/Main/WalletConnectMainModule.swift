import UIKit
import ThemeKit
import RxSwift
import WalletConnect

protocol IWalletConnectMainService {
    var activeAccountName: String? { get }
    var appMetaItem: WalletConnectMainModule.AppMetaItem? { get }
    var allowedBlockchains: [WalletConnectMainModule.Blockchain] { get }
    var allowedBlockchainsObservable: Observable<[WalletConnectMainModule.Blockchain]> { get }
    var hint: String? { get }
    var state: WalletConnectMainModule.State { get }
    var connectionState: WalletConnectMainModule.ConnectionState { get }

    var stateObservable: Observable<WalletConnectMainModule.State> { get }
    var connectionStateObservable: Observable<WalletConnectMainModule.ConnectionState> { get }
    var errorObservable: Observable<Error> { get }

    func toggle(chainId: Int)
    func reconnect()
    func approveSession()
    func rejectSession()
    func killSession()
}

protocol IWalletConnectMainRequestView {

}

struct WalletConnectMainModule {

    static func viewController(session: WalletConnectSession, sourceViewController: UIViewController?) -> UIViewController? {
        let service = WalletConnectV1MainService(
                session: session,
                manager: App.shared.walletConnectManager,
                sessionManager: App.shared.walletConnectSessionManager,
                reachabilityManager: App.shared.reachabilityManager,
                accountManager: App.shared.accountManager,
                evmBlockchainManager: App.shared.evmBlockchainManager
        )

        return viewController(service: service, sourceViewController: sourceViewController)
    }

    static func viewController(session: Session, sourceViewController: UIViewController?) -> UIViewController? {
        let service = App.shared.walletConnectV2SessionManager.service
        let pingService = WalletConnectV2PingService(service: service)

        let mainService = WalletConnectV2MainService(
                session: session,
                service: service,
                pingService: pingService,
                manager: App.shared.walletConnectManager,
                reachabilityManager: App.shared.reachabilityManager,
                accountManager: App.shared.accountManager,
                evmBlockchainManager: App.shared.evmBlockchainManager,
                evmChainParser: WalletConnectEvmChainParser()
        )

        return viewController(service: mainService, sourceViewController: sourceViewController)
    }

    static func viewController(service: IWalletConnectMainService, sourceViewController: UIViewController?) -> UIViewController? {
        let viewModel = WalletConnectMainViewModel(service: service)
        let viewController = WalletConnectMainViewController(viewModel: viewModel, sourceViewController: sourceViewController)
        switch service {
        case let service as WalletConnectV1MainService:
            let requestViewModel = WalletConnectV1MainRequestViewModel(service: service)
            let requestView = WalletConnectV1MainRequestView(viewModel: requestViewModel)
            requestView.sourceViewController = viewController

            viewController.requestView = requestView
        case is WalletConnectV2MainService: ()
        default: return nil
        }

        return ThemeNavigationController(rootViewController: viewController)
    }

}

extension WalletConnectMainModule {

    struct AppMetaItem {
        let editable: Bool
        let name: String
        let url: String
        let description: String
        let icons: [String]
    }

    struct Blockchain: Hashable {
        let chainId: Int
        let evmBlockchain: EvmBlockchain
        let address: String
        let selected: Bool

        func hash(into hasher: inout Hasher) {
            hasher.combine(chainId)
        }

        static func ==(lhs: Blockchain, rhs: Blockchain) -> Bool {
            lhs.chainId == rhs.chainId
        }

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
        case unsupportedChainId
        case noSuitableAccount
    }

}
