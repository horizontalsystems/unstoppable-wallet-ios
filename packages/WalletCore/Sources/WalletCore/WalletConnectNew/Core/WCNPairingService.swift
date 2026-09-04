import Combine
import Foundation
import ReownWalletKit

class WCNPairingService {
    private let signClient: IWCNSignClient
    private let proposalTimeout: TimeInterval
    private let waitingSubject = CurrentValueSubject<Bool, Never>(false)

    init(signClient: IWCNSignClient, proposalTimeout: TimeInterval = 5) {
        self.signClient = signClient
        self.proposalTimeout = proposalTimeout
    }

    var isWaitingPublisher: AnyPublisher<Bool, Never> {
        waitingSubject.eraseToAnyPublisher()
    }

    // pairs and waits for the dApp's proposal; the proposal itself is delivered through the sign client publisher
    func pair(uri uriString: String) async throws {
        let uri: WalletConnectURI
        do {
            uri = try WalletConnectURI(uriString: uriString)
        } catch WalletConnectURI.Errors.expired {
            throw PairingError.expiredUri
        } catch {
            throw PairingError.invalidUri
        }
        guard uri.version == "2" else {
            throw PairingError.unsupportedVersion
        }

        waitingSubject.send(true)
        defer { waitingSubject.send(false) }

        try await signClient.pair(uri: uri)
        try await waitForProposal()
    }

    private func waitForProposal() async throws {
        let proposals = signClient.sessionProposalPublisher.map { _ in () }.values
        let timeout = proposalTimeout

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                for await _ in proposals {
                    return
                }
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw PairingError.proposalTimeout
            }
            try await group.next()
            group.cancelAll()
        }
    }
}

extension WCNPairingService {
    enum PairingError: Error, Equatable, LocalizedError {
        case invalidUri
        case expiredUri
        case unsupportedVersion
        case proposalTimeout

        var errorDescription: String? {
            switch self {
            case .invalidUri, .unsupportedVersion: return "wallet_connect.error.invalid_url".localized
            case .expiredUri: return "wallet_connect.error.expired_url".localized
            case .proposalTimeout: return "alert.try_again".localized
            }
        }
    }
}
