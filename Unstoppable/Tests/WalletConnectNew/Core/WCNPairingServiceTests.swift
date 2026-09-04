import Combine
import Foundation
import ReownWalletKit
import Testing
@testable import WalletCore

struct WCNPairingServiceTests {
    private let client = WCNSpySignClient()

    private func uri(version: String = "2", expiry: UInt64 = UInt64(Date().timeIntervalSince1970) + 300) -> String {
        "wc:\(WCNTestFixtures.topic)@\(version)?relay-protocol=irn&symKey=\(String(repeating: "ab", count: 32))&expiryTimestamp=\(expiry)"
    }

    @Test func invalidUriIsRejectedWithoutPairing() async {
        let service = WCNPairingService(signClient: client, proposalTimeout: 0.2)
        await #expect(throws: WCNPairingService.PairingError.invalidUri) {
            try await service.pair(uri: "not a wallet connect uri")
        }
        #expect(client.pairedUris.isEmpty)
    }

    @Test func expiredUriIsReportedSeparately() async {
        let service = WCNPairingService(signClient: client, proposalTimeout: 0.2)
        await #expect(throws: WCNPairingService.PairingError.expiredUri) {
            try await service.pair(uri: uri(expiry: 1))
        }
        #expect(client.pairedUris.isEmpty)
    }

    @Test func version1IsUnsupported() async {
        let service = WCNPairingService(signClient: client, proposalTimeout: 0.2)
        await #expect(throws: WCNPairingService.PairingError.unsupportedVersion) {
            try await service.pair(uri: uri(version: "1"))
        }
    }

    @Test func proposalArrivingInTimeCompletesPairing() async throws {
        let service = WCNPairingService(signClient: client, proposalTimeout: 2)
        let proposal = try WCNPairingFixtures.proposal()

        let uri = uri()
        let pairing = Task { try await service.pair(uri: uri) }
        try await Task.sleep(nanoseconds: 100_000_000)
        client.sessionProposalSubject.send((proposal: proposal, context: nil))
        try await pairing.value

        #expect(client.pairedUris.count == 1)
        #expect(client.pairedUris[0].topic == WCNTestFixtures.topic)
    }

    @Test func missingProposalTimesOut() async {
        let service = WCNPairingService(signClient: client, proposalTimeout: 0.2)
        await #expect(throws: WCNPairingService.PairingError.proposalTimeout) {
            try await service.pair(uri: uri())
        }
        #expect(client.pairedUris.count == 1)
    }

    @Test func relayFailurePropagates() async {
        client.pairError = RelayDown()
        let service = WCNPairingService(signClient: client, proposalTimeout: 0.2)
        await #expect(throws: RelayDown.self) {
            try await service.pair(uri: uri())
        }
    }
}

private struct RelayDown: Error {}
