import Combine
import Foundation
import MarketKit
import ReownWalletKit
import WalletConnectUtils

// The connect (proposal) screen. An approved session is never opened as a screen (parity with Android),
// so this view model only ever describes a pending proposal.
class WCConnectViewModel: ObservableObject {
    enum DAppCheck {
        case locked // scam protection off: tapping the row opens the purchase flow
        case secure
        case risky
        case unavailable
        case hidden // still loading, nothing to show yet
    }

    private let item: WCProposalItem
    private let manager: WCManager?
    private let accountManager = Core.shared.accountManager

    let dAppName: String
    let dAppHost: String
    let iconUrl: String?
    let accountName: String?
    let blockchainTypes: [BlockchainType]
    let unsupported: Bool
    // protocol origin attestation shown on top (Android VerificationAlert); nil = nothing to report
    let verificationCaution: CautionNew?

    @Published private(set) var defenseState: WCDefenseState = .disabled
    @Published private(set) var connecting = false

    private let finishSubject = PassthroughSubject<Void, Never>()
    private let errorSubject = PassthroughSubject<String, Never>()
    private(set) var finished = false

    init(item: WCProposalItem) {
        self.item = item
        manager = Core.shared.walletConnect

        let proposer = item.proposal.proposer
        dAppName = proposer.name
        dAppHost = URLComponents(string: proposer.url)?.host ?? proposer.url
        iconUrl = proposer.icons.first
        accountName = accountManager.activeAccount?.name

        let registry = manager?.chainSupportRegistry
        var types = [BlockchainType]()
        for chain in item.blockchainProposals.map(\.chain) {
            if let type = registry?.support(namespace: chain.namespace)?.blockchainType(chain: chain), !types.contains(type) {
                types.append(type)
            }
        }
        blockchainTypes = types

        let kit = try? manager?.kit()
        unsupported = item.blockchainProposals.isEmpty || kit?.validationError(for: item.proposal) != nil
        defenseState = kit?.defenseState(context: item.context) ?? .disabled
        verificationCaution = Self.verificationCaution(for: item.verifyState, origin: item.context?.origin)

        WCLog.log("connect vm: \(dAppName) host=\(dAppHost) account=\(accountName ?? "nil") types=\(types.map(\.uid)) unsupported=\(unsupported) defense=\(defenseState)")
    }

    // scam and mismatch are red, an unverified origin is a yellow caution; a valid origin shows nothing
    private static func verificationCaution(for state: WCVerifyState, origin: String?) -> CautionNew? {
        switch state {
        case .scam:
            return CautionNew(title: "wallet_connect.defense.scam.title".localized, text: "wallet_connect.defense.scam.text".localized, type: .error)
        case .invalid:
            let host = origin.flatMap { URLComponents(string: $0)?.host }
            let text = host.map { "wallet_connect.verify.mismatch.text".localized($0) } ?? "wallet_connect.verify.mismatch.no_origin".localized
            return CautionNew(title: "wallet_connect.verify.mismatch.title".localized, text: text, type: .error)
        case .unknown:
            return CautionNew(title: "wallet_connect.verify.unknown.title".localized, text: "wallet_connect.verify.unknown.text".localized, type: .warning)
        case .verified, .trusted:
            return nil
        }
    }

    var finishPublisher: AnyPublisher<Void, Never> { finishSubject.eraseToAnyPublisher() }
    var errorPublisher: AnyPublisher<String, Never> { errorSubject.eraseToAnyPublisher() }

    var dAppCheck: DAppCheck {
        switch defenseState {
        case .disabled: return .locked
        case .loading: return .hidden
        case .notAvailable: return .unavailable
        case .safe: return .secure
        case .danger, .scam: return .risky
        }
    }

    // the premium "Danger!" plaque; scam is surfaced by the top alert instead, so it is never doubled here
    var showDanger: Bool {
        defenseState == .danger
    }

    var connectEnabled: Bool {
        !unsupported && defenseState != .scam && !connecting
    }

    func refreshDefense() {
        guard let kit = try? manager?.kit() else { return }
        defenseState = kit.defenseState(context: item.context)
    }

    func connect() {
        guard let kit = try? manager?.kit() else { return }
        WCLog.log("connect vm: connect tapped")
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

    func reject() {
        guard !finished, let kit = try? manager?.kit() else { return }
        WCLog.log("connect vm: reject")
        finished = true
        Task {
            try? await kit.reject(proposal: item.proposal)
        }
    }

    @MainActor private func finish() {
        WCLog.log("connect vm: finished")
        connecting = false
        finished = true
        finishSubject.send()
    }

    @MainActor private func fail(_ error: Error) {
        WCLog.log("connect vm: failed \(error)")
        connecting = false
        errorSubject.send(error.smartDescription)
    }
}
