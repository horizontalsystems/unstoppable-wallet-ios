import Combine
import Foundation
import ReownWalletKit

class WCNPairingService {
    private let signClient: IWCNSignClient
    private let proposalTimeout: TimeInterval
    private let proposalCount = CurrentValueSubject<Int, Never>(0)
    private var cancellables = Set<AnyCancellable>()

    init(signClient: IWCNSignClient, proposalTimeout: TimeInterval = 5) {
        self.signClient = signClient
        self.proposalTimeout = proposalTimeout

        // subscribed up front: the relay can deliver the proposal before pair() returns
        signClient.sessionProposalPublisher
            .sink { [proposalCount] in
                WCNLog.log("pairing: proposal event id=\($0.proposal.id) count=\(proposalCount.value + 1)")
                proposalCount.send(proposalCount.value + 1)
            }
            .store(in: &cancellables)
    }

    // pairs and waits for the dApp's proposal; the proposal itself is delivered through the sign client publisher
    func pair(uri uriString: String) async throws {
        let uri: WalletConnectURI
        do {
            uri = try WalletConnectURI(uriString: uriString)
        } catch WalletConnectURI.Errors.expired {
            WCNLog.log("pairing: expired uri \(uriString.prefix(120))")
            throw PairingError.expiredUri
        } catch {
            WCNLog.log("pairing: invalid uri \(error) raw=\(uriString.prefix(120)) length=\(uriString.count)")
            throw PairingError.invalidUri
        }
        guard uri.version == "2" else {
            throw PairingError.unsupportedVersion
        }

        let seen = proposalCount.value
        WCNLog.log("pairing: uri topic=\(uri.topic.prefix(8)) relay=\(uri.relay.protocol) seen=\(seen)")

        // the SDK's pair() may never return even though the proposal arrives, so only its failure is raced against the proposal
        let pairFailure = Future<Void, Error> { [signClient] promise in
            Task {
                do {
                    try await signClient.pair(uri: uri)
                } catch {
                    promise(.failure(error))
                }
            }
        }
        try await waitForProposal(after: seen, pairFailure: pairFailure)
        WCNLog.log("pairing: proposal received")
    }

    private func waitForProposal(after seen: Int, pairFailure: Future<Void, Error>) async throws {
        let proposals = proposalCount
            .filter { $0 > seen }
            .map { _ in () }
            .setFailureType(to: Error.self)
            .merge(with: pairFailure)
            .timeout(.seconds(proposalTimeout), scheduler: DispatchQueue.global(), customError: { PairingError.proposalTimeout })
            .values

        for try await _ in proposals {
            return
        }
        throw PairingError.proposalTimeout
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
