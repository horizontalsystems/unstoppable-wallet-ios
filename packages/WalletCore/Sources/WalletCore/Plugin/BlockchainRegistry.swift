import MarketKit

/// The plugins `Core` was started with, indexed once at init. Immutable, safe to read from any thread.
public final class BlockchainRegistry {
    public let plugins: [BlockchainPlugin]

    let adapterCapabilities: [AdapterCapability]
    let lifecycleCapabilities: [LifecycleCapability]
    let sendCapabilities: [SendCapability]
    let restoreSettingsCapabilities: [RestoreSettingsCapability]
    let networkSettingsCapabilities: [NetworkSettingsCapability]
    let swapCapabilities: [SwapCapability]
    let tokenCapabilities: [TokenCapability]
    let accountCapabilities: [AccountCapability]

    private let descriptorsByType: [BlockchainType: BlockchainDescriptor]
    private let pluginsByType: [BlockchainType: BlockchainPlugin]

    public init(plugins: [BlockchainPlugin]) {
        let (accepted, conflicts) = Self.resolve(plugins: plugins)

        if !conflicts.isEmpty {
            assertionFailure("Conflicting blockchain plugins dropped: \(conflicts)")
        }

        var descriptorsByType = [BlockchainType: BlockchainDescriptor]()
        var pluginsByType = [BlockchainType: BlockchainPlugin]()

        for plugin in accepted {
            for descriptor in plugin.descriptors {
                descriptorsByType[descriptor.type] = descriptor
                pluginsByType[descriptor.type] = plugin
            }
        }

        self.plugins = accepted
        self.descriptorsByType = descriptorsByType
        self.pluginsByType = pluginsByType
        adapterCapabilities = accepted.compactMap { $0 as? AdapterCapability }
        lifecycleCapabilities = accepted.compactMap { $0 as? LifecycleCapability }
        sendCapabilities = accepted.compactMap { $0 as? SendCapability }
        restoreSettingsCapabilities = accepted.compactMap { $0 as? RestoreSettingsCapability }
        networkSettingsCapabilities = accepted.compactMap { $0 as? NetworkSettingsCapability }
        swapCapabilities = accepted.compactMap { $0 as? SwapCapability }
        tokenCapabilities = accepted.compactMap { $0 as? TokenCapability }
        accountCapabilities = accepted.compactMap { $0 as? AccountCapability }
    }

    public func descriptor(for type: BlockchainType) -> BlockchainDescriptor? {
        descriptorsByType[type]
    }

    public func plugin(for type: BlockchainType) -> BlockchainPlugin? {
        pluginsByType[type]
    }

    public func plugin<T: BlockchainPlugin>(_: T.Type) -> T? {
        for plugin in plugins {
            if let plugin = plugin as? T {
                return plugin
            }
        }

        return nil
    }

    func adapterCapability(for type: BlockchainType) -> AdapterCapability? {
        pluginsByType[type] as? AdapterCapability
    }

    func swapCapability(for type: BlockchainType) -> SwapCapability? {
        pluginsByType[type] as? SwapCapability
    }

    func addressCapability(for type: BlockchainType) -> AddressCapability? {
        pluginsByType[type] as? AddressCapability
    }

    func accountCapability(for type: BlockchainType) -> AccountCapability? {
        pluginsByType[type] as? AccountCapability
    }

    func transactionSummary(record: TransactionRecord) -> TransactionSummary? {
        (pluginsByType[record.source.blockchainType] as? TransactionPresentationCapability)?.summary(record: record)
    }

    func bootstrap(context: PluginContext) throws {
        try bootstrap { try $0.bootstrap(context: context) }
    }

    func bootstrap(using run: (BlockchainPlugin) throws -> Void) throws {
        for plugin in plugins {
            try run(plugin)
        }
    }
}

extension BlockchainRegistry {
    struct Conflict: Equatable {
        let pluginId: String
        let blockchainType: BlockchainType?
    }

    /// Walks `plugins` in order and drops, whole, a plugin whose id or one of whose blockchain types
    /// is already claimed by an accepted plugin: the first one wins.
    static func resolve(plugins: [BlockchainPlugin]) -> (accepted: [BlockchainPlugin], conflicts: [Conflict]) {
        var accepted = [BlockchainPlugin]()
        var conflicts = [Conflict]()
        var claimedIds = Set<String>()
        var claimedTypes = Set<BlockchainType>()

        for plugin in plugins {
            if claimedIds.contains(plugin.id) {
                conflicts.append(Conflict(pluginId: plugin.id, blockchainType: nil))
                continue
            }

            if let claimed = plugin.descriptors.first(where: { claimedTypes.contains($0.type) }) {
                conflicts.append(Conflict(pluginId: plugin.id, blockchainType: claimed.type))
                continue
            }

            claimedIds.insert(plugin.id)
            claimedTypes.formUnion(plugin.descriptors.map(\.type))
            accepted.append(plugin)
        }

        return (accepted, conflicts)
    }
}
