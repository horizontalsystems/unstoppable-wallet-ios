public protocol INodeProvider: AnyObject {
    var currentNodeId: String { get }
    func nodes() -> (defaultNodes: [NodeNetworkItem], customNodes: [NodeNetworkItem])
    func validate(id: String) async throws
    // Both MUST fire the chain's node-updated relay: its consumer (AdapterManager) switches
    // the live adapter and reverts the stored selection on failure. Never switch it here.
    func setCurrent(id: String) // manual pick: with stat event
    func applyNode(id: String) // auto-select result: no stat event
}

public struct NodeNetworkItem: Identifiable {
    public let id: String
    public let name: String
    public let url: String

    public init(id: String, name: String, url: String) {
        self.id = id
        self.name = name
        self.url = url
    }
}
