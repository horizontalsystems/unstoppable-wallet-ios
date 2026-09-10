import Foundation
import Testing
import WalletConnectSign
@testable import WalletCore

struct WCRequestTests {
    @Test(arguments: ["eip155:1", "solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp", "stellar:pubnet"])
    func payloadPreservesDeadlineAcrossChains(chainId: String) throws {
        var raw = try WCTestFixtures.request(chainId: chainId)
        raw.expiryTimestamp = 1234
        let payload = WCRequestPayload(request: raw, kind: .transaction, from: nil)

        #expect(payload.expiryTimestamp == 1234)
        let request = WCRequest(payload: payload, verdict: .pass, dAppName: "dApp")
        #expect(request.expirationDate == Date(timeIntervalSince1970: 1234))
    }

    @Test func deadlineBoundaryUsesSeconds() {
        #expect(WCRequest.isExpired(expiryTimestamp: 1000, now: Date(timeIntervalSince1970: 999.999)) == false)
        #expect(WCRequest.isExpired(expiryTimestamp: 1000, now: Date(timeIntervalSince1970: 1000)))
        #expect(WCRequest.isExpired(expiryTimestamp: 1000, now: Date(timeIntervalSince1970: 1001)))
        #expect(WCRequest.isExpired(expiryTimestamp: nil, now: Date(timeIntervalSince1970: 1001)) == false)
    }

    @Test func expiredRequestFailsExecutionCheck() throws {
        var raw = try WCTestFixtures.request()
        raw.expiryTimestamp = 0
        let request = WCRequest(payload: WCRequestPayload(request: raw, kind: .transaction, from: nil), verdict: .pass, dAppName: "dApp")

        #expect(request.isExpired)
        #expect(throws: WCRequest.RequestError.expired) { try request.checkExpiration() }
    }

    @Test func missingDeadlineDoesNotInventExpiration() throws {
        var raw = try WCTestFixtures.request()
        raw.expiryTimestamp = nil
        let request = WCRequest(payload: WCRequestPayload(request: raw, kind: .transaction, from: nil), verdict: .pass, dAppName: "dApp")

        #expect(request.isExpired == false)
        #expect(request.expirationDate == nil)
        #expect(throws: Never.self) { try request.checkExpiration() }
    }
}
