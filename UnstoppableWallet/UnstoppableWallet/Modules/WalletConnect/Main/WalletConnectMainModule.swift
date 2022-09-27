import UIKit
import ThemeKit
import RxSwift
import WalletConnectSign
import WalletConnectUtils
import MarketKit

protocol IWalletConnectMainService {
    var activeAccountName: String? { get }
    var appMetaItem: WalletConnectMainModule.AppMetaItem? { get }
    var allowedBlockchains: [WalletConnectMainModule.BlockchainItem] { get }
    var allowedBlockchainsObservable: Observable<[WalletConnectMainModule.BlockchainItem]> { get }
    var hint: String? { get }
    var state: WalletConnectMainModule.State { get }
    var connectionState: WalletConnectMainModule.ConnectionState { get }

    var stateObservable: Observable<WalletConnectMainModule.State> { get }
    var connectionStateObservable: Observable<WalletConnectMainModule.ConnectionState> { get }
    var errorObservable: Observable<Error> { get }

    func select(chainId: Int)
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
        let service = try? WalletConnectV1MainService(
                session: session,
                manager: App.shared.walletConnectManager,
                sessionManager: App.shared.walletConnectSessionManager,
                reachabilityManager: App.shared.reachabilityManager,
                accountManager: App.shared.accountManager,
                evmBlockchainManager: App.shared.evmBlockchainManager
        )

        return service.flatMap { viewController(service: $0, sourceViewController: sourceViewController) }
    }

    static func viewController(session: WalletConnectSign.Session, sourceViewController: UIViewController?) -> UIViewController? {
        let service = App.shared.walletConnectV2SessionManager.service
        let pingService = WalletConnectV2PingService(service: service, socketConnectionService: App.shared.walletConnectV2SocketConnectionService, logger: App.shared.logger)

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

    struct BlockchainSet {
        static var empty: BlockchainSet = BlockchainSet(items: Set(), methods: Set(), events: Set())

        var items: Set<BlockchainItem>
        let methods: Set<String>
        let events: Set<String>
    }

    struct BlockchainItem: Hashable {
        let namespace: String
        let chainId: Int
        let blockchain: MarketKit.Blockchain
        let address: String
        let selected: Bool

        func hash(into hasher: inout Hasher) {
            hasher.combine(chainId)
        }

        static func ==(lhs: BlockchainItem, rhs: BlockchainItem) -> Bool {
            lhs.chainId == rhs.chainId
        }

    }

    enum State: Equatable {
        case idle
        case invalid(error: Error)
        case waitingForApproveSession
        case ready
        case killed(reason: KilledReason)

        static func ==(lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle): return true
            case (.invalid(let lhsError), .invalid(let rhsError)): return "\(lhsError)" == "\(rhsError)"
            case (.waitingForApproveSession, .waitingForApproveSession): return true
            case (.ready, .ready): return true
            case (.killed(let reason), .killed(let reason2)): return reason == reason2
            default: return false
            }
        }
    }

    enum KilledReason: String {
        case rejectProposal = "reject proposal"
        case rejectSession = "reject session"
        case killSession = "kill session"
    }

    enum ConnectionState {
        case connected
        case connecting
        case disconnected
    }

    enum SessionError: Error {
        case noAnySupportedChainId
        case unsupportedChainId
        case noSuitableAccount
    }

}
