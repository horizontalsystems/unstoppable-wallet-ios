import MarketKit

// Per-chain capability bundle for the network screen: nil slots hide their UI —
// no engine = no auto-select toggle and no pings, no custom handler = no Added/Add New.
public struct NodeNetworkHandlers {
    public let nodeProvider: INodeProvider
    public let autoSelectEngine: INodeAutoSelectEngine?
    public let updateSignalProvider: IUpdateSignalProvider?
    public let customNodeHandler: ICustomNodeHandler?

    public init(nodeProvider: INodeProvider, autoSelectEngine: INodeAutoSelectEngine?, updateSignalProvider: IUpdateSignalProvider?, customNodeHandler: ICustomNodeHandler?) {
        self.nodeProvider = nodeProvider
        self.autoSelectEngine = autoSelectEngine
        self.updateSignalProvider = updateSignalProvider
        self.customNodeHandler = customNodeHandler
    }
}

open class NodeNetworkHandlerProvider {
    public init() {}

    open class func instance(blockchain _: Blockchain) -> NodeNetworkHandlers? { nil }
}
