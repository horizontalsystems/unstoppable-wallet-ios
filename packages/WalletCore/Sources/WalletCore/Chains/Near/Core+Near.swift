/// Temporary forwarders for the NEAR call sites not yet migrated to the plugin; phase 1b removes them.
extension Core {
    var nearNodeManager: NearNodeManager {
        nearPlugin.nodeManager
    }

    var nearKitManager: NearKitManager {
        nearPlugin.kitManager
    }

    private var nearPlugin: NearPlugin {
        guard let plugin = registry.plugin(NearPlugin.self) else {
            preconditionFailure("NearPlugin is not registered")
        }
        return plugin
    }
}
