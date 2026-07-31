import BigInt
import Foundation
import MarketKit
import Testing
import ThorChainKit
@testable import WalletCore

struct ThorChainAdapterTests {
    @Test func concreteKitWrapperProvidesCanonicalAddressAndInitialBalance() throws {
        let adapter = try Self.adapter()

        #expect(adapter.receiveAddress.address == adapter.thorChainKitWrapper.thorChainKit.address.raw)
        #expect(adapter.balanceData.total == 0)
        #expect(adapter.balanceState == .notSynced(error: "idle"))
    }

    @Test func adapterStopsConcreteKit() throws {
        let adapter = try Self.adapter()

        adapter.stop()
        adapter.stop()

        #expect(adapter.thorChainKitWrapper.thorChainKit.syncState == .idle(cached: false))
    }

    @Test func runeConversionUsesEightDecimalsWithoutDouble() throws {
        let oneRune = try ThorChainAdapter.balanceData(baseUnits: 100_000_000, decimals: 8)
        #expect(oneRune.total == 1)

        let oneBaseUnit = try ThorChainAdapter.balanceData(baseUnits: 1, decimals: 8)
        #expect(oneBaseUnit.total == Decimal(string: "0.00000001"))
        do {
            _ = try ThorChainAdapter.balanceData(baseUnits: 1, decimals: 39)
            Issue.record("invalid decimals were accepted")
        } catch {
            #expect((error as? ThorChainAdapterError) == .invalidDecimals)
        }

        do {
            _ = try ThorChainAdapter.balanceData(
                baseUnits: BigUInt("100000000000000000000000000000000000000000000000001"),
                decimals: 8
            )
            Issue.record("precision loss was accepted")
        } catch {
            #expect((error as? ThorChainAdapterError) == .balancePrecisionLoss)
        }
    }

    @Test func adapterExposesConcreteKitWithoutAccountIdentity() throws {
        let adapter = try Self.adapter()
        let labels = Set(Mirror(reflecting: adapter).children.compactMap(\.label))

        #expect(adapter.thorChainKitWrapper.thorChainKit.address.raw == adapter.receiveAddress.address)
        #expect(!labels.contains("wallet"))
        #expect(!labels.contains("accountId"))
    }

    private static func adapter() throws -> ThorChainAdapter {
        let address = try ThorChainKit.Address(
            "thor1x0jkvqdh2hlpeztd5zyyk70n3efx6mhudkmnn2",
            network: .mainnet
        )
        let endpoints = try ThorChainKit.EndpointConfiguration(families: [
            ThorChainKit.EndpointFamilyDescriptor(
                id: "adapter-test",
                cosmosRestURL: URL(string: "https://adapter-rest.example")!,
                cometBftURL: URL(string: "https://adapter-rpc.example")!
            ),
        ])
        let kit = try ThorChainKit.Kit.instance(address: address, walletId: "adapter-\(UUID().uuidString)", endpoints: endpoints)
        return try ThorChainAdapter(thorChainKitWrapper: ThorChainKitWrapper(thorChainKit: kit, signer: nil))
    }
}
