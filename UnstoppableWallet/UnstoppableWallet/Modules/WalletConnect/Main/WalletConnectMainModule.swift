import MarketKit
import RxSwift
import SwiftUI

import UIKit
import WalletConnectSign
import WalletConnectUtils

enum WalletConnectMainModule {
    static func viewController(account: Account, session: WalletConnectSign.Session? = nil, proposal: WalletConnectSign.Session.Proposal? = nil, sourceViewController: UIViewController?, viaPushing: Bool = false) -> UIViewController {
        let service = Core.shared.walletConnectSessionManager.service

        let chain = ProposalChain()
        let walletConnectRequestHandler = Core.shared.walletConnectRequestHandler
        chain.append(handler: Eip155ProposalHandler(evmBlockchainManager: Core.shared.evmBlockchainManager, account: account, supportedMethods: walletConnectRequestHandler.supportedMethodsBy(namespace: Eip155ProposalHandler.namespace)))

        chain.append(handler: StellarProposalHandler(stellarKitManager: Core.shared.stellarKitManager, account: account, supportedMethods: walletConnectRequestHandler.supportedMethodsBy(namespace: StellarProposalHandler.namespace)))

        let mainService = WalletConnectMainService(
            session: session,
            proposal: proposal,
            service: service,
            reachabilityManager: Core.shared.reachabilityManager,
            accountManager: Core.shared.accountManager,
            proposalHandler: chain
        )

        return viewController(service: mainService, sourceViewController: sourceViewController, viaPushing: viaPushing)
    }

    static func viewController(service: WalletConnectMainService, sourceViewController: UIViewController?, viaPushing: Bool = false) -> UIViewController {
        let viewModel = WalletConnectMainViewModel(service: service)
        let viewController = WalletConnectMainViewController(
            viewModel: viewModel,
            requestViewFactory: Core.shared.walletConnectRequestHandler,
            sourceViewController: sourceViewController,
            viaPushing: viaPushing
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

        if viaPushing {
            return viewController
        }
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

    struct BlockchainProposal {
        let item: BlockchainItem
        var methods: Set<String>
        var events: Set<String>

        mutating func formUnion(_ set: Self) {
            guard item.namespace == set.item.namespace else {
                return
            }

            methods.formUnion(set.methods)
            events.formUnion(set.events)
        }
    }

    struct BlockchainItem: Hashable {
        let namespace: String
        let chainId: String
        let blockchain: MarketKit.Blockchain
        let address: String

        func hash(into hasher: inout Hasher) {
            hasher.combine(namespace)
            hasher.combine(chainId)
        }

        static func == (lhs: BlockchainItem, rhs: BlockchainItem) -> Bool {
            lhs.namespace == rhs.namespace && lhs.chainId == rhs.chainId
        }

        func equal(blockchain: WalletConnectSign.Blockchain) -> Bool {
            namespace == blockchain.namespace && chainId == blockchain.reference
        }
    }

    enum WhitelistState: String {
        case deactivated
        case loading
        case secure
        case risky
        case notAvailable

        var showAlert: Bool {
            switch self {
            case .loading, .secure: return false
            default: return true
            }
        }

        var alertTitle: String {
            switch self {
            case .deactivated: return "alert_card.title.caution".localized
            case .risky: return "wallet_connect.main.premium_alert.title.risky".localized
            case .notAvailable: return "alert_card.title.critical".localized
            case .loading, .secure: return ""
            }
        }

        var alertSubtitle: String {
            switch self {
            case .deactivated: return "wallet_connect.main.premium_alert.subtitle.deactivated".localized
            case .risky: return "wallet_connect.main.premium_alert.subtitle.risky".localized
            case .notAvailable: return "wallet_connect.main.premium_alert.subtitle.not_available".localized
            case .loading, .secure: return ""
            }
        }

        var alertTitleColor: UIColor {
            switch self {
            case .deactivated, .notAvailable: return .themeJacob
            case .risky: return .themeLucian
            case .loading, .secure: return .themeGray50
            }
        }

        var alertIcon: String {
            switch self {
            case .deactivated, .notAvailable, .risky: return "warning_filled"
            case .loading, .secure: return ""
            }
        }

        var protectionValue: String? {
            switch self {
            case .deactivated: return "wallet_connect.scam_protection.deactivated".localized
            case .risky: return "wallet_connect.scam_protection.risky".localized
            case .notAvailable: return "wallet_connect.scam_protection.not_available".localized
            case .secure: return "wallet_connect.scam_protection.secure".localized
            case .loading: return nil
            }
        }

        var protectionIcon: String? {
            switch self {
            case .deactivated: return "lock"
            case .risky: return "warning_filled"
            case .notAvailable: return nil
            case .secure: return "shield_check_filled"
            case .loading: return nil
            }
        }

        var protectionValueColor: UIColor {
            switch self {
            case .deactivated: return .themeJacob
            case .risky: return .themeLucian
            case .notAvailable: return .themeLeah
            case .secure: return .themeRemus
            case .loading: return .themeGray
            }
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
