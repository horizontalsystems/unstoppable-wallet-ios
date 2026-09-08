import Combine
import Foundation
import ReownWalletKit
import Testing
@testable import WalletCore

struct WCPairingServiceTests {
    private let client = WCSpySignClient()

    private func uri(version: String = "2", expiry: UInt64 = UInt64(Date().timeIntervalSince1970) + 300) -> String {
        "wc:\(WCTestFixtures.topic)@\(version)?relay-protocol=irn&symKey=\(String(repeating: "ab", count: 32))&expiryTimestamp=\(expiry)"
    }

    @Test func invalidUriIsRejectedWithoutPairing() async {
        let service = WCPairingService(signClient: client, proposalTimeout: 0.2)
        await #expect(throws: WCPairingService.PairingError.invalidUri) {
            try await service.pair(uri: "not a wallet connect uri")
        }
        #expect(client.pairedUris.isEmpty)
    }

    @Test func expiredUriIsReportedSeparately() async {
        let service = WCPairingService(signClient: client, proposalTimeout: 0.2)
        await #expect(throws: WCPairingService.PairingError.expiredUri) {
            try await service.pair(uri: uri(expiry: 1))
        }
        #expect(client.pairedUris.isEmpty)
    }

    @Test func version1IsUnsupported() async {
        let service = WCPairingService(signClient: client, proposalTimeout: 0.2)
        await #expect(throws: WCPairingService.PairingError.unsupportedVersion) {
            try await service.pair(uri: uri(version: "1"))
        }
    }

    @Test func proposalArrivingInTimeCompletesPairing() async throws {
        let service = WCPairingService(signClient: client, proposalTimeout: 2)
        let proposal = try WCPairingFixtures.proposal()

        let uri = uri()
        let pairing = Task { try await service.pair(uri: uri) }
        try await Task.sleep(nanoseconds: 100_000_000)
        client.sessionProposalSubject.send((proposal: proposal, context: nil))
        try await pairing.value

        #expect(client.pairedUris.count == 1)
        #expect(client.pairedUris[0].topic == WCTestFixtures.topic)
    }

    @Test func proposalDeliveredDuringPairIsNotMissed() async throws {
        let service = WCPairingService(signClient: client, proposalTimeout: 0.2)
        let proposal = try WCPairingFixtures.proposal()
        client.onPair = { [client] in client.sessionProposalSubject.send((proposal: proposal, context: nil)) }

        try await service.pair(uri: uri())

        #expect(client.pairedUris.count == 1)
    }

    @Test func missingProposalTimesOut() async {
        let service = WCPairingService(signClient: client, proposalTimeout: 0.2)
        await #expect(throws: WCPairingService.PairingError.proposalTimeout) {
            try await service.pair(uri: uri())
        }
        #expect(client.pairedUris.count == 1)
    }

    @Test func relayFailurePropagates() async {
        client.pairError = RelayDown()
        let service = WCPairingService(signClient: client, proposalTimeout: 0.2)
        await #expect(throws: RelayDown.self) {
            try await service.pair(uri: uri())
        }
    }
}

private struct RelayDown: Error {}
