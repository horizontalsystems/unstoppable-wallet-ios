import UIKit
import ThemeKit
import RxSwift
import WalletConnectSign
import WalletConnectUtils
import MarketKit

struct WalletConnectMainModule {

    static func viewController(session: WalletConnectSign.Session? = nil, proposal: WalletConnectSign.Session.Proposal? = nil, sourceViewController: UIViewController?) -> UIViewController? {
        let service = App.shared.walletConnectSessionManager.service

        let mainService = WalletConnectMainService(
                session: session,
                proposal: proposal,
                service: service,
                manager: App.shared.walletConnectManager,
                reachabilityManager: App.shared.reachabilityManager,
                accountManager: App.shared.accountManager,
                evmBlockchainManager: App.shared.evmBlockchainManager
        )

        return viewController(service: mainService, sourceViewController: sourceViewController)
    }

    static func viewController(service: WalletConnectMainService, sourceViewController: UIViewController?) -> UIViewController? {
        let viewModel = WalletConnectMainViewModel(service: service)
        let viewController = WalletConnectMainViewController(viewModel: viewModel, sourceViewController: sourceViewController)

        let pendingRequestService = WalletConnectMainPendingRequestService(
                service: service,
                accountManager: App.shared.accountManager,
                sessionManager: App.shared.walletConnectSessionManager,
                evmBlockchainManager: App.shared.evmBlockchainManager,
                signService: App.shared.walletConnectSessionManager.service)
        let pendingRequestViewModel = WalletConnectMainPendingRequestViewModel(service: pendingRequestService)
        viewController.pendingRequestViewModel = pendingRequestViewModel

        return ThemeNavigationController(rootViewController: viewController)
    }

}

extension WalletConnectMainModule {

    struct AppMetaItem {
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
