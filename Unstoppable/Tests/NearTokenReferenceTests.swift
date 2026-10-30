import Foundation
import MarketKit
import Testing
@testable import WalletCore

/// Adding a NEP-141 token by its contract id or a NearBlocks link (Android `AddNearTokenBlockchainService`).
struct NearTokenReferenceTests {
    private let service = AddNearTokenBlockchainService(
        blockchain: Blockchain(type: .near, name: "Near Protocol", explorerUrl: nil),
        rpcUrls: []
    )

    @Test func contractIdIsTheTokenType() throws {
        try service.validate(reference: "usdt.tether-token.near")

        #expect(service.tokenQuery(reference: "usdt.tether-token.near").tokenType == .nep141(contractId: "usdt.tether-token.near"))
    }

    @Test func nearBlocksLinkIsAccepted() {
        #expect(AddNearTokenBlockchainService.contractId(reference: "https://nearblocks.io/token/usdt.tether-token.near") == "usdt.tether-token.near")
        #expect(AddNearTokenBlockchainService.contractId(reference: "https://nearblocks.io/token/usdt.tether-token.near/?tab=holders") == "usdt.tether-token.near")
    }

    /// a contract id that only starts like a link is still an id, as on Android
    @Test func contractIdStartingWithHttpIsAccepted() {
        #expect(AddNearTokenBlockchainService.contractId(reference: "http.near") == "http.near")
        #expect(AddNearTokenBlockchainService.contractId(reference: "httpcoin.near") == "httpcoin.near")
    }

    @Test func referenceIsTrimmedAndLowercased() {
        #expect(AddNearTokenBlockchainService.contractId(reference: "  USDT.Tether-Token.NEAR  ") == "usdt.tether-token.near")
    }

    @Test func invalidReferenceIsRefused() {
        #expect(throws: AddNearTokenBlockchainService.TokenError.self) { try service.validate(reference: "not a contract") }
        #expect(throws: AddNearTokenBlockchainService.TokenError.self) { try service.validate(reference: "https://nearblocks.io/address/alice.near") }
        #expect(throws: AddNearTokenBlockchainService.TokenError.self) { try service.validate(reference: "") }
    }
}
