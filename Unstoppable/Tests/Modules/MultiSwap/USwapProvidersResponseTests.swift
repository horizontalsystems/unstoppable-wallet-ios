import Foundation
import ObjectMapper
import Testing
@testable import WalletCore

/// GET /v3/providers is a top-level array keyed by `provider`; `privacy` is "none" | "basic" | "split"
struct USwapProvidersResponseTests {
    private typealias Response = USwapMultiSwapApi.ProviderDescriptorResponse

    @Test func confidentialProviderParses() throws {
        let response = try Mapper<Response>().map(JSON: [
            "provider": "NEAR_CONFIDENTIAL",
            "executionType": "transfer",
            "privacy": "basic",
            "amlPolicy": "fair",
            "suspended": false,
            "supportedChainIds": ["bitcoin", "1"],
        ])

        #expect(response.id == "NEAR_CONFIDENTIAL")
        #expect(response.confidential)
        #expect(response.privacy == "basic")
        #expect(response.executionType == "transfer")
        #expect(response.amlPolicy == "fair")
        #expect(!response.suspended)
        #expect(response.supportedChainIds == ["bitcoin", "1"])
    }

    @Test func splitPrivacyIsConfidential() throws {
        let response = try Mapper<Response>().map(JSON: [
            "provider": "NEAR_CONFIDENTIAL_ADVANCED",
            "executionType": "transfer",
            "privacy": "split",
        ])

        #expect(response.confidential)
        #expect(response.privacy == "split")
    }

    @Test func publicProviderIsNotConfidential() throws {
        let response = try Mapper<Response>().map(JSON: [
            "provider": "THORCHAIN",
            "privacy": "none",
            "executionType": "thorchain_deposit",
        ])

        #expect(!response.confidential)
    }

    @Test func unknownPrivacyValueIsNotConfidential() throws {
        let response = try Mapper<Response>().map(JSON: [
            "provider": "NEAR",
            "executionType": "transfer",
            "privacy": "ultra",
        ])

        #expect(!response.confidential)
        #expect(response.privacy == "ultra")
    }

    @Test func missingPrivacyDefaultsToPublic() throws {
        let response = try Mapper<Response>().map(JSON: [
            "provider": "THORCHAIN",
            "executionType": "thorchain_deposit",
        ])

        #expect(!response.confidential)
        #expect(response.privacy == "none")
    }

    @Test func quotesFalseEntryHasEmptyExecutionType() throws {
        let response = try Mapper<Response>().map(JSON: [
            "provider": "ALLBRIDGE",
            "quotes": false,
            "privacy": "none",
        ])

        #expect(response.executionType == "")
    }

    @Test func missingProviderIdThrows() {
        #expect(throws: (any Error).self) {
            try Mapper<Response>().map(JSON: ["id": "NEAR_CONFIDENTIAL"])
        }
    }

    @Test func liveArrayMapsEveryEntry() throws {
        let responses = try Mapper<Response>().mapArray(JSONArray: [
            ["provider": "THORCHAIN", "executionType": "thorchain_deposit", "privacy": "none", "amlPolicy": "excellent"],
            ["provider": "NEAR_CONFIDENTIAL", "executionType": "transfer", "privacy": "basic", "amlPolicy": "fair"],
            ["provider": "NEAR_CONFIDENTIAL_ADVANCED", "executionType": "transfer", "privacy": "split", "amlPolicy": "fair"],
        ])

        #expect(responses.map(\.descriptor.id) == ["THORCHAIN", "NEAR_CONFIDENTIAL", "NEAR_CONFIDENTIAL_ADVANCED"])
        #expect(responses.map(\.descriptor.confidential) == [false, true, true])
    }
}
