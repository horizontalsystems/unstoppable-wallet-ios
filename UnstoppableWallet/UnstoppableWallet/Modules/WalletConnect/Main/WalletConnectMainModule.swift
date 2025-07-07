import MarketKit
import RxSwift
import SwiftUI

import UIKit
import WalletConnectSign
import WalletConnectUtils

enum WalletConnectMainModule {
    static func viewController(account: Account, session: WalletConnectSign.Session? = nil, proposal: WalletConnectSign.Session.Proposal? = nil, sourceViewController: UIViewController?) -> UIViewController {
        let service = Core.shared.walletConnectSessionManager.service

        let chain = ProposalChain()
        let supportedMethods = Core.shared.walletConnectRequestHandler.supportedMethods
        chain.append(handler: Eip155ProposalHandler(evmBlockchainManager: Core.shared.evmBlockchainManager, account: account, supportedMethods: supportedMethods))

        let mainService = WalletConnectMainService(
            session: session,
            proposal: proposal,
            service: service,
            reachabilityManager: Core.shared.reachabilityManager,
            accountManager: Core.shared.accountManager,
            proposalHandler: chain,
            proposalValidator: ProposalValidator()
        )

        return viewController(service: mainService, sourceViewController: sourceViewController)
    }

    static func viewController(service: WalletConnectMainService, sourceViewController: UIViewController?) -> UIViewController {
        let viewModel = WalletConnectMainViewModel(service: service)
        let viewController = WalletConnectMainViewController(
            viewModel: viewModel,
            requestViewFactory: Core.shared.walletConnectRequestHandler,
            sourceViewController: sourceViewController
        )

        let pendingRequestService = WalletConnectMainPendingRequestService(
            service: service,
            accountManager: Core.shared.accountManager,
            sessionManager: Core.shared.walletConnectSessionManager,
            requestHandler: Core.shared.walletConnectRequestHandler,
            evmBlockchainManager: Core.shared.evmBlockchainManager,
            signService: Core.shared.walletConnectSessionManager.service
        )
        let pendingRequestViewModel = WalletConnectMainPendingRequestViewModel(service: pendingRequestService)
        viewController.pendingRequestViewModel = pendingRequestViewModel

        return ThemeNavigationController(rootViewController: viewController)
    }
}

struct WalletConnectMainView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    let account: Account
    let session: WalletConnectSign.Session?
    let proposal: WalletConnectSign.Session.Proposal?

    func makeUIViewController(context _: Context) -> UIViewController {
        WalletConnectMainModule.viewController(account: account, session: session, proposal: proposal, sourceViewController: nil)
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}

extension WalletConnectMainModule {
    struct AppMetaItem {
        let name: String
        let url: String
        let description: String
        let icons: [String]
    }

    struct BlockchainSet {
        static var empty: BlockchainSet = .init(items: [], methods: Set(), events: Set())

        var items: [BlockchainItem]
        var methods: Set<String>
        var events: Set<String>

        mutating func formUnion(_ set: Self) {
            items.append(contentsOf: set.items)
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
