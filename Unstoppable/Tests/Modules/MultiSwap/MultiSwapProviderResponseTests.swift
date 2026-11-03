import Foundation
import ObjectMapper
import Testing
@testable import WalletCore

/// The provider directory's view of GET /v3/providers: `name`, `privacy`, `executionType`, `amlPolicy`,
/// `splitSwaps`; wholly suspended rows are dropped at sync.
struct MultiSwapProviderResponseTests {
    private typealias Response = MultiSwapProviderManager.ProviderResponse

    @Test func v3FieldsParse() throws {
        let response = try Mapper<Response>().map(JSON: [
            "provider": "NEAR_CONFIDENTIAL",
            "name": "NEAR Confidential",
            "executionType": "transfer",
            "privacy": "basic",
            "amlPolicy": "fair",
            "splitSwaps": false,
            "suspended": false,
        ])

        #expect(response.provider == "NEAR_CONFIDENTIAL")
        #expect(response.name == "NEAR Confidential")
        #expect(response.executionType == "transfer")
        #expect(response.privacy == "basic")
        #expect(response.amlPolicy == "fair")
        #expect(!response.splitSwaps)
        #expect(!response.suspended)
    }

    @Test func missingFieldsDefault() throws {
        let response = try Mapper<Response>().map(JSON: ["provider": "SWAPUZ"])

        #expect(response.name == nil)
        #expect(response.privacy == "none")
        #expect(!response.splitSwaps)
        #expect(response.quotes)
        #expect(!response.suspended)
    }

    @Test func splitProviderParses() throws {
        let response = try Mapper<Response>().map(JSON: [
            "provider": "SWAPUZ_SPLIT",
            "quotes": false,
            "splitSwaps": true,
            "amlPolicy": "fair",
        ])

        #expect(!response.quotes)
        #expect(response.splitSwaps)
    }

    @Test func splitProvidersAreThoseWithSplitSwaps() {
        let records = [
            Self.record(providerId: "SWAPUZ", splitSwaps: false),
            Self.record(providerId: "SWAPUZ_SPLIT", splitSwaps: true),
        ]

        #expect(MultiSwapProviderManager.splitProviderIds(records: records) == ["SWAPUZ_SPLIT"])
    }

    @Test func recordNameFallsBackToHumanizedIdOnlyWhenAbsent() throws {
        let named = try Mapper<Response>().map(JSON: ["provider": "PANCAKESWAP_API", "name": "PancakeSwap"])
        let unnamed = try Mapper<Response>().map(JSON: ["provider": "PANCAKESWAP_API"])
        let empty = try Mapper<Response>().map(JSON: ["provider": "PANCAKESWAP_API", "name": ""])

        #expect(MultiSwapProviderManager.record(response: named, position: 0, timestamp: 0).name == "PancakeSwap")
        #expect(MultiSwapProviderManager.record(response: unnamed, position: 0, timestamp: 0).name == "Pancakeswap Api")
        #expect(MultiSwapProviderManager.record(response: empty, position: 0, timestamp: 0).name == "Pancakeswap Api")
    }

    @Test func humanizedIdSplitsUnderscores() {
        #expect(SwapVenue.humanized(id: "NEAR_CONFIDENTIAL") == "Near Confidential")
        #expect(SwapVenue.humanized(id: "EXOLIX") == "Exolix")
        #expect(SwapVenue.unknown(id: "LI.FI").name == "Li.fi")
        #expect(!SwapVenue.unknown(id: "X").isKnown)
    }

    @Test func venueTypeOverriddenByRouteAmlPolicy() {
        let venue = SwapVenue(id: "QUICKEX", name: "QuickEx", type: .good, privacy: "none", executionType: "transfer", isKnown: true)

        #expect(venue.overriding(amlPolicy: "fair").type == .fair)
        #expect(venue.overriding(amlPolicy: nil).type == .good)
        #expect(venue.overriding(amlPolicy: "legendary").type == .good)
        #expect(SwapVenue.unknown(id: "NEW").overriding(amlPolicy: "excellent").type == .excellent)
    }

    // MARK: - RateRequest parameters

    @Test func rateRequestOmitsPrivacyAndProvidersByDefault() {
        let parameters = USwapMultiSwapApi.RateRequest(sellAsset: "BTC.BTC", buyAsset: "ETH.ETH", sellAmount: 1, slippage: 1, chainId: "bitcoin").parameters

        #expect(parameters["privacy"] == nil)
        #expect(parameters["providers"] == nil)
        #expect(parameters["chainId"] as? String == "bitcoin")
        #expect(parameters["sellAmount"] as? String == "1")
    }

    @Test func rateRequestSendsPrivacyList() {
        let parameters = USwapMultiSwapApi.RateRequest(sellAsset: "ETH.ETH", buyAsset: "ETH.ETH", amount: .buy(1), slippage: 1, chainId: "1", privacy: ["basic"]).parameters

        #expect(parameters["privacy"] as? [String] == ["basic"])
        #expect(parameters["providers"] == nil)
        #expect(parameters["buyAmount"] as? String == "1")
    }

    @Test func rateRequestSendsProvidersOnlyWhenNamed() {
        let parameters = USwapMultiSwapApi.RateRequest(sellAsset: "BTC.BTC", buyAsset: "ETH.ETH", sellAmount: 1, slippage: 1, chainId: nil, providerIds: ["EXOLIX"]).parameters

        #expect(parameters["providers"] as? [String] == ["EXOLIX"])
        #expect(parameters["chainId"] == nil)
    }

    private static func record(providerId: String, splitSwaps: Bool) -> SwapProviderRecord {
        SwapProviderRecord(
            providerId: providerId,
            position: 0,
            name: providerId,
            executionType: "transfer",
            amlPolicy: "fair",
            privacy: "none",
            splitSwaps: splitSwaps,
            lastSyncTimestamp: 0
        )
    }
}
