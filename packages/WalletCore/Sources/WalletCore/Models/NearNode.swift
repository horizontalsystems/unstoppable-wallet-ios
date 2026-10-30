import Foundation
import NearKit

struct NearNode: Equatable {
    let name: String
    let url: URL
}

extension NearNode {
    /// Android NearRpcSourceManager names
    private static let names: [String: String] = [
        "free.rpc.fastnear.com": "FastNEAR",
        "rpc.testnet.fastnear.com": "FastNEAR",
        "near.drpc.org": "dRPC",
        "rpc.shitzuapes.xyz": "Shitzu",
        "rpc.mainnet.near.org": "NEAR.org",
        "rpc.testnet.near.org": "NEAR.org",
    ]

    static func defaultNodes(network: NearKit.Network) -> [NearNode] {
        network.rpcUrls.map { url in
            let host = url.host ?? url.absoluteString
            return NearNode(name: names[host] ?? host, url: url)
        }
    }
}
