import Combine
import MarketKit
import Testing
@testable import WalletCore

struct BlockchainRegistryTests {
    @Test func resolveKeepsFirstOnDuplicateType() {
        let first = FakePlugin(id: "first", types: [.near])
        let second = FakePlugin(id: "second", types: [.near])

        let (accepted, conflicts) = BlockchainRegistry.resolve(plugins: [first, second])

        #expect(ids(accepted) == ["first"])
        #expect(conflicts == [BlockchainRegistry.Conflict(pluginId: "second", blockchainType: .near)])
    }

    @Test func resolveKeepsFirstOnDuplicateId() {
        let first = FakePlugin(id: "same", types: [.near])
        let second = FakePlugin(id: "same", types: [.solana])

        let (accepted, conflicts) = BlockchainRegistry.resolve(plugins: [first, second])

        #expect(accepted.count == 1)
        #expect(accepted.first === first)
        #expect(conflicts == [BlockchainRegistry.Conflict(pluginId: "same", blockchainType: nil)])
    }

    @Test func resolveAcceptsDisjointPlugins() {
        let plugins = [
            FakePlugin(id: "a", types: [.near]),
            FakePlugin(id: "b", types: [.solana, .ton]),
            FakePlugin(id: "c", types: [.xrp]),
        ]

        let (accepted, conflicts) = BlockchainRegistry.resolve(plugins: plugins)

        #expect(ids(accepted) == ["a", "b", "c"])
        #expect(conflicts.isEmpty)
    }

    @Test func unregisteredTypeHasNoDescriptorOrPlugin() {
        let registry = BlockchainRegistry(plugins: [FakeAdapterPlugin(id: "near", types: [.near])])

        #expect(registry.descriptor(for: .bitcoin) == nil)
        #expect(registry.plugin(for: .bitcoin) == nil)
        #expect(registry.adapterCapability(for: .bitcoin) == nil)
    }

    @Test func lookupByTypeAndByPluginType() {
        let adapterPlugin = FakeAdapterPlugin(id: "near", types: [.near])
        let plainPlugin = FakePlugin(id: "multi", types: [.solana, .ton])
        let registry = BlockchainRegistry(plugins: [adapterPlugin, plainPlugin])

        #expect(registry.descriptor(for: .near)?.type == .near)
        #expect(registry.descriptor(for: .near)?.family == "near")
        #expect(registry.descriptor(for: .ton)?.family == "multi")
        #expect(registry.plugin(for: .near) === adapterPlugin)
        #expect(registry.plugin(for: .solana) === plainPlugin)
        #expect(registry.plugin(for: .ton) === plainPlugin)
        #expect(registry.plugin(FakeAdapterPlugin.self) === adapterPlugin)
        #expect(registry.plugin(FakeLifecyclePlugin.self) == nil)
    }

    @Test func capabilityListsFollowRegistrationOrder() {
        let lifecycle = FakeLifecyclePlugin(id: "lifecycle", types: [.xrp])
        let plain = FakePlugin(id: "plain", types: [.solana])
        let adapterA = FakeAdapterPlugin(id: "adapterA", types: [.near])
        let adapterB = FakeAdapterPlugin(id: "adapterB", types: [.ton])
        let registry = BlockchainRegistry(plugins: [lifecycle, plain, adapterA, adapterB])

        #expect(ids(registry.adapterCapabilities) == ["adapterA", "adapterB"])
        #expect(ids(registry.lifecycleCapabilities) == ["lifecycle"])
        #expect(registry.adapterCapability(for: .near) === adapterA)
        #expect(registry.adapterCapability(for: .ton) === adapterB)
        #expect(registry.adapterCapability(for: .solana) == nil)
        #expect(registry.adapterCapability(for: .xrp) == nil)
    }

    @Test func bootstrapRunsOncePerPluginInOrderAndRethrows() throws {
        let registry = BlockchainRegistry(plugins: [
            FakePlugin(id: "a", types: [.near]),
            FakePlugin(id: "b", types: [.solana]),
            FakePlugin(id: "c", types: [.ton]),
        ])

        var log = [String]()
        try registry.bootstrap { log.append($0.id) }

        #expect(log == ["a", "b", "c"])

        var failingLog = [String]()
        #expect(throws: BootstrapError.failed) {
            try registry.bootstrap { plugin in
                failingLog.append(plugin.id)
                if plugin.id == "b" {
                    throw BootstrapError.failed
                }
            }
        }

        #expect(failingLog == ["a", "b"])
    }

    @Test func watchParserOrderEqualsLegacyOrder() {
        let btcTypes = BtcBlockchainManager.blockchainTypes.map { WatchViewModel.WatchParserEntry(blockchainType: $0, withEns: false) }
        let head = [WatchViewModel.WatchParserEntry(blockchainType: .ethereum, withEns: true)] + btcTypes
        let middle: [BlockchainType] = [.tron, .ton, .thorChain, .mayaChain, .solana, .stellar, .xrp]

        let withNear = WatchViewModel.watchParserEntries(pluginSupports: [WatchAddressSupport(blockchainType: .near, priority: 1000)])
        let withoutNear = WatchViewModel.watchParserEntries(pluginSupports: [])

        #expect(withNear == head + (middle + [.near, .monero]).map { WatchViewModel.WatchParserEntry(blockchainType: $0, withEns: true) })
        #expect(withoutNear == head + (middle + [.monero]).map { WatchViewModel.WatchParserEntry(blockchainType: $0, withEns: true) })
    }

    private func ids(_ plugins: [BlockchainPlugin]) -> [String] {
        plugins.map(\.id)
    }

    private func ids(_ plugins: [AdapterCapability]) -> [String] {
        plugins.map(\.id)
    }

    private func ids(_ plugins: [LifecycleCapability]) -> [String] {
        plugins.map(\.id)
    }
}

private enum BootstrapError: Error {
    case failed
}

private class FakePlugin: BlockchainPlugin {
    let id: String
    let descriptors: [BlockchainDescriptor]

    init(id: String, types: [BlockchainType]) {
        self.id = id
        descriptors = types.map { BlockchainDescriptor(type: $0, family: id) }
    }

    func bootstrap(context _: PluginContext) throws {}
}

private final class FakeAdapterPlugin: FakePlugin, AdapterCapability {
    func adapter(wallet _: Wallet) -> IAdapter? {
        nil
    }

    func transactionsAdapter(source _: TransactionSource, walletAdapter _: IAdapter) -> ITransactionsAdapter? {
        nil
    }

    var adaptersInvalidated: AnyPublisher<BlockchainType, Never> {
        Empty().eraseToAnyPublisher()
    }
}

private final class FakeLifecyclePlugin: FakePlugin, LifecycleCapability {
    func didEnterBackground() {}
    func willEnterForeground() {}
    func clear(exceptAccountIds _: [String]) throws {}
}
