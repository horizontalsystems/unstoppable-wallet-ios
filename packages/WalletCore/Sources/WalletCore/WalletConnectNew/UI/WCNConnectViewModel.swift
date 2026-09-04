import Combine
import Foundation
import MarketKit
import ReownWalletKit
import WalletConnectUtils

// One screen for both a pending proposal and an approved session, as Android WCSessionSheet
class WCNConnectViewModel: ObservableObject {
    private enum Mode {
        case proposal(WCNProposalItem)
        case session(WCNSessionItem)
    }

    private let mode: Mode
    private let manager: WCNManager?
    private let accountManager = Core.shared.accountManager

    let dAppName: String
    let dAppHost: String
    let iconUrl: String?
    let accountName: String?
    let blockchainTypes: [BlockchainType]
    let unsupported: Bool

    @Published private(set) var defenseState: WCNDefenseState = .disabled
    @Published private(set) var connecting = false

    private let finishSubject = PassthroughSubject<Void, Never>()
    private let errorSubject = PassthroughSubject<String, Never>()
    private(set) var finished = false

    convenience init(item: WCNProposalItem) {
        let proposer = item.proposal.proposer
        self.init(mode: .proposal(item), name: proposer.name, url: proposer.url, iconUrl: proposer.icons.first, chains: item.blockchainProposals.map(\.chain))
    }

    convenience init(session: WCNSessionItem) {
        self.init(mode: .session(session), name: session.dAppName, url: session.peer?.url ?? "", iconUrl: session.peer?.icons.first, chains: session.namespaces.accounts.map(\.blockchain))
    }

    private init(mode: Mode, name: String, url: String, iconUrl: String?, chains: [WalletConnectUtils.Blockchain]) {
        self.mode = mode
        manager = Core.shared.walletConnectNew

        dAppName = name
        dAppHost = URLComponents(string: url)?.host ?? url
        self.iconUrl = iconUrl
        accountName = accountManager.activeAccount?.name

        let registry = manager?.chainSupportRegistry
        var types = [BlockchainType]()
        for chain in chains {
            if let type = registry?.support(namespace: chain.namespace)?.blockchainType(chain: chain), !types.contains(type) {
                types.append(type)
            }
        }
        blockchainTypes = types

        let kit = try? manager?.kit()
        switch mode {
        case let .proposal(item):
            unsupported = item.blockchainProposals.isEmpty || kit?.validationError(for: item.proposal) != nil
            defenseState = kit?.defenseState(context: item.context) ?? .disabled
        case .session:
            unsupported = false
            defenseState = kit?.defenseState(peerUrl: url) ?? .disabled
        }
        WCNLog.log("connect vm: \(dAppName) connected=\(connected) host=\(dAppHost) account=\(accountName ?? "nil") types=\(types.map(\.uid)) unsupported=\(unsupported) defense=\(defenseState)")
    }

    var finishPublisher: AnyPublisher<Void, Never> { finishSubject.eraseToAnyPublisher() }
    var errorPublisher: AnyPublisher<String, Never> { errorSubject.eraseToAnyPublisher() }

    var connected: Bool {
        if case .session = mode { return true }
        return false
    }

    var connectEnabled: Bool {
        !unsupported && defenseState != .scam && !connecting
    }

    func refreshDefense() {
        guard let kit = try? manager?.kit() else { return }
        switch mode {
        case let .proposal(item): defenseState = kit.defenseState(context: item.context)
        case let .session(session): defenseState = kit.defenseState(peerUrl: session.peer?.url ?? "")
        }
    }

    func connect() {
        guard case let .proposal(item) = mode, let kit = try? manager?.kit() else { return }
        WCNLog.log("connect vm: connect tapped")
        connecting = true

        Task { [weak self] in
            do {
                try await kit.approve(proposal: item.proposal, selected: item.blockchainProposals)
                await self?.finish()
            } catch {
                await self?.fail(error)
            }
        }
    }

    func disconnect() {
        guard case let .session(session) = mode, let kit = manager?.startedKit else { return }
        WCNLog.log("connect vm: disconnect tapped")
        connecting = true

        Task { [weak self] in
            do {
                try await kit.disconnect(topic: session.topic)
                await self?.finish()
            } catch {
                await self?.fail(error)
            }
        }
    }

    func reject() {
        guard case let .proposal(item) = mode, !finished, let kit = try? manager?.kit() else { return }
        WCNLog.log("connect vm: reject")
        finished = true
        Task {
            try? await kit.reject(proposal: item.proposal)
        }
    }

    @MainActor private func finish() {
        WCNLog.log("connect vm: finished")
        connecting = false
        finished = true
        finishSubject.send()
    }

    @MainActor private func fail(_ error: Error) {
        WCNLog.log("connect vm: failed \(error)")
        connecting = false
        errorSubject.send(error.smartDescription)
    }
}
