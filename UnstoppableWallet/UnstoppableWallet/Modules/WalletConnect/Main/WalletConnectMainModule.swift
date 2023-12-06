import MarketKit
import RxSwift
import ThemeKit
import UIKit
import WalletConnectSign
import WalletConnectUtils

enum WalletConnectMainModule {
    static func viewController(session: WalletConnectSign.Session? = nil, proposal: WalletConnectSign.Session.Proposal? = nil, sourceViewController: UIViewController?) -> UIViewController? {
        guard let account = App.shared.accountManager.activeAccount else {
            return nil
        }

        let service = App.shared.walletConnectSessionManager.service

        let chain = ProposalChain()
        let supportedMethods = App.shared.walletConnectRequestHandler.supportedMethods
        chain.append(handler: Eip155ProposalHandler(evmBlockchainManager: App.shared.evmBlockchainManager, account: account, supportedMethods: supportedMethods))

        let mainService = WalletConnectMainService(
            session: session,
            proposal: proposal,
            service: service,
            manager: App.shared.walletConnectManager,
            reachabilityManager: App.shared.reachabilityManager,
            accountManager: App.shared.accountManager,
            proposalHandler: chain,
            proposalValidator: ProposalValidator()
        )

        return viewController(service: mainService, sourceViewController: sourceViewController)
    }

    static func viewController(service: WalletConnectMainService, sourceViewController: UIViewController?) -> UIViewController? {
        let viewModel = WalletConnectMainViewModel(service: service)
        let viewController = WalletConnectMainViewController(
            viewModel: viewModel,
            requestViewFactory: App.shared.walletConnectRequestHandler,
            sourceViewController: sourceViewController
        )

        let pendingRequestService = WalletConnectMainPendingRequestService(
            service: service,
            accountManager: App.shared.accountManager,
            sessionManager: App.shared.walletConnectSessionManager,
            requestHandler: App.shared.walletConnectRequestHandler,
            evmBlockchainManager: App.shared.evmBlockchainManager,
            signService: App.shared.walletConnectSessionManager.service
        )
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
        static var empty: BlockchainSet = .init(items: Set(), methods: Set(), events: Set())

        var items: Set<BlockchainItem>
        var methods: Set<String>
        var events: Set<String>

        mutating func formUnion(_ set: Self) {
            items.formUnion(set.items)
            methods.formUnion(set.methods)
            events.formUnion(set.events)
        }
    }

    struct BlockchainItem: Hashable {
        let namespace: String
        let chainId: Int
        let blockchain: MarketKit.Blockchain
        let address: String

        func hash(into hasher: inout Hasher) {
            hasher.combine(chainId)
        }

        static func == (lhs: BlockchainItem, rhs: BlockchainItem) -> Bool {
            lhs.chainId == rhs.chainId
        }

        func equal(blockchain: WalletConnectSign.Blockchain) -> Bool {
            namespace == blockchain.namespace && chainId.description == blockchain.reference
        }
    }

    enum State: Equatable {
        case idle
        case invalid(error: Error)
        case waitingForApproveSession
        case ready
        case killed(reason: KilledReason)

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle): return true
            case let (.invalid(lhsError), .invalid(rhsError)): return "\(lhsError)" == "\(rhsError)"
            case (.waitingForApproveSession, .waitingForApproveSession): return true
            case (.ready, .ready): return true
            case let (.killed(reason), .killed(reason2)): return reason == reason2
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
