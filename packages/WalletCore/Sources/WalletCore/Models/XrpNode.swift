import Foundation
import XrpKit

struct XrpNode: Equatable {
    let name: String
    let url: URL
}

extension XrpNode {
    /// The kit owns the list for both networks (XrpKit `Network.rpcUrls`); the app only chooses
    /// which of them leads it, so there is nothing to duplicate here.
    static func defaultNodes(network: XrpKit.Network) -> [XrpNode] {
        network.rpcUrls.map { XrpNode(name: $0.host ?? $0.absoluteString, url: $0) }
    }
}
