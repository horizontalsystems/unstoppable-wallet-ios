import Foundation
import MarketKit
import ObjectMapper
import Testing
@testable import WalletCore

/// "Can this token be sent privately": the catalog's providers for the token intersected with the synced
/// providers that are private, settle as a plain `transfer` and are not suspended.
struct USwapPrivateSendGateTests {
    private static let privateIds: Set<String> = ["NEAR_CONFIDENTIAL", "OTHER_PRIVATE"]

    @Test(arguments: [BlockchainType.monero, .zcash, .zano])
    func privacyNativeChainsAreExcluded(_ blockchainType: BlockchainType) {
        let entry = USwapCatalogEntry(identifier: "X.X", providerIds: ["NEAR_CONFIDENTIAL"])

        #expect(USwapPrivateSendGate.privateVenueIds(entry: entry, blockchainType: blockchainType, privateProviderIds: Self.privateIds).isEmpty)
    }

    @Test func intersectionKeepsCatalogOrder() {
        let entry = USwapCatalogEntry(identifier: "ETH.ETH", providerIds: ["OTHER_PRIVATE", "THORCHAIN", "NEAR_CONFIDENTIAL", "EXOLIX"])

        #expect(USwapPrivateSendGate.privateVenueIds(entry: entry, blockchainType: .ethereum, privateProviderIds: Self.privateIds) == ["OTHER_PRIVATE", "NEAR_CONFIDENTIAL"])
    }

    @Test func emptyProvidersAndNilEntryYieldNothing() {
        let entry = USwapCatalogEntry(identifier: "ETH.ETH", providerIds: [])

        #expect(USwapPrivateSendGate.privateVenueIds(entry: entry, blockchainType: .ethereum, privateProviderIds: Self.privateIds).isEmpty)
        #expect(USwapPrivateSendGate.privateVenueIds(entry: nil, blockchainType: .ethereum, privateProviderIds: Self.privateIds).isEmpty)
    }

    @Test func publicOnlyTokenYieldsNothing() {
        let entry = USwapCatalogEntry(identifier: "ETH.ETH", providerIds: ["THORCHAIN", "EXOLIX"])

        #expect(USwapPrivateSendGate.privateVenueIds(entry: entry, blockchainType: .ethereum, privateProviderIds: Self.privateIds).isEmpty)
    }

    // MARK: - privateProviderIds derivation from the synced rows

    @Test func privateProviderIdsRequirePrivacyAndTransfer() {
        let records = [
            Self.record("NEAR_CONFIDENTIAL", privacy: "basic", executionType: "transfer"),
            Self.record("NEAR", privacy: "none", executionType: "transfer"),
            Self.record("PRIVATE_DEX", privacy: "basic", executionType: "signed_transaction"),
            Self.record("FUTURE_RAIL", privacy: "advanced", executionType: "transfer"),
        ]

        #expect(MultiSwapProviderManager.privateProviderIds(records: records) == ["NEAR_CONFIDENTIAL", "FUTURE_RAIL"])
    }

    /// A wholly suspended provider never reaches the records (dropped at sync), so it is never private either.
    @Test func suspendedProviderIsDroppedBeforeTheRecords() throws {
        let response = try MultiSwapProviderManager.ProviderResponse(JSON: [
            "provider": "NEAR_CONFIDENTIAL_ADVANCED",
            "privacy": "basic",
            "executionType": "transfer",
            "suspended": true,
        ])

        #expect(response.suspended)
    }

    @Test func privacyLevelsExcludeNoneAndFallBackToBasic() {
        let synced = [
            Self.record("NEAR", privacy: "none", executionType: "transfer"),
            Self.record("NEAR_CONFIDENTIAL", privacy: "basic", executionType: "transfer"),
            Self.record("FUTURE_RAIL", privacy: "advanced", executionType: "transfer"),
        ]

        #expect(MultiSwapProviderManager.privacyLevelsExcludingNone(records: synced) == ["advanced", "basic"])
        #expect(MultiSwapProviderManager.privacyLevelsExcludingNone(records: [Self.record("NEAR", privacy: "none", executionType: "transfer")]) == ["basic"])
        #expect(MultiSwapProviderManager.privacyLevelsExcludingNone(records: []) == ["basic"])
    }

    private static func record(_ id: String, privacy: String, executionType: String) -> SwapProviderRecord {
        SwapProviderRecord(providerId: id, position: 0, name: id, executionType: executionType, amlPolicy: "fair", privacy: privacy, splitSwaps: false, lastSyncTimestamp: 0)
    }
}
