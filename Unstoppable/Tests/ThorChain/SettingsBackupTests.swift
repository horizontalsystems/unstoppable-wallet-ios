import Foundation
import Testing
@testable import WalletCore

struct SettingsBackupTests {
    @Test func encodesOnlySelectedThorChainFamilyId() throws {
        let data = try JSONEncoder().encode(backup(thorChainEndpoint: .init(familyId: "second")))
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let thorChainEndpoint = try #require(object["thorchain_endpoint"] as? [String: String])

        #expect(thorChainEndpoint == ["family_id": "second"])
    }

    @Test func decodesBackupWithoutThorChainEndpoint() throws {
        let data = try JSONEncoder().encode(backup(thorChainEndpoint: .init(familyId: "second")))
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object.removeValue(forKey: "thorchain_endpoint")

        let dataWithoutThorChainEndpoint = try JSONSerialization.data(withJSONObject: object)
        let decoded = try JSONDecoder().decode(SettingsBackup.self, from: dataWithoutThorChainEndpoint)

        #expect(decoded.thorChainEndpoint.familyId == nil)
    }

    private func backup(thorChainEndpoint: ThorChainEndpointManager.EndpointBackup) -> SettingsBackup {
        SettingsBackup(
            evmSyncSources: .init(selected: [], custom: []),
            moneroNodes: .init(selected: [], custom: []),
            zanoNodes: .init(selected: [], custom: []),
            zcashEndpoints: .init(selected: [], custom: []),
            thorChainEndpoint: thorChainEndpoint,
            btcModes: [],
            remoteContactsSync: nil,
            swapProviders: [],
            chartIndicators: .init(ma: [], rsi: [], macd: []),
            indicatorsShown: true,
            currentLanguage: "en",
            baseCurrency: "USD",
            mode: .system,
            showMarketTab: true,
            priceChangeMode: .hour24,
            launchScreen: .auto,
            conversionTokenQueryId: nil,
            balanceHideButtons: false,
            balancePrimaryValue: .coin,
            balanceAutoHide: false,
            appIcon: "Main"
        )
    }
}
