import Foundation
import ObjectMapper
import Testing
@testable import WalletCore

// The swap screen's view of GET /v3/providers: `quotes` decides the Standard tab, `splitSwaps` the Private tab
struct MultiSwapProviderResponseTests {
    private typealias Response = MultiSwapProviderManager.ProviderResponse

    @Test func quotesFalseSplitProviderParses() throws {
        let response = try Mapper<Response>().map(JSON: [
            "provider": "SWAPUZ_SPLIT",
            "quotes": false,
            "splitSwaps": true,
            "amlPolicy": "fair",
            "suspensions": [],
        ])

        #expect(response.provider == "SWAPUZ_SPLIT")
        #expect(!response.quotes)
        #expect(response.split)
    }

    @Test func missingQuotesDefaultsToTrue() throws {
        let response = try Mapper<Response>().map(JSON: ["provider": "SWAPUZ"])

        #expect(response.quotes)
        #expect(!response.split)
    }

    @Test func quotableAndSplitListsArePartitioned() {
        let records = [
            Self.record(providerId: "SWAPUZ", position: 0, quotes: true, split: false),
            Self.record(providerId: "SWAPUZ_SPLIT", position: 1, quotes: false, split: true),
        ]

        #expect(MultiSwapProviderManager.quotableProviderIds(records: records) == ["SWAPUZ"])
        #expect(MultiSwapProviderManager.splitProviderIds(records: records) == ["SWAPUZ_SPLIT"])
    }

    private static func record(providerId: String, position: Int, quotes: Bool, split: Bool) -> SwapProviderRecord {
        SwapProviderRecord(
            providerId: providerId,
            position: position,
            executionType: "transfer",
            amlPolicy: "fair",
            split: split,
            quotes: quotes,
            suspensions: nil,
            lastSyncTimestamp: 0
        )
    }
}
