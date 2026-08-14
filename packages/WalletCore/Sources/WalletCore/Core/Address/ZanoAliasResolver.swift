import Alamofire
import Foundation
import HsToolKit
import MarketKit

class ZanoAliasResolver {
    private let zanoNodeManager: ZanoNodeManager
    private let networkManager: NetworkManager

    init(zanoNodeManager: ZanoNodeManager, networkManager: NetworkManager) {
        self.zanoNodeManager = zanoNodeManager
        self.networkManager = networkManager
    }

    /// Resolves an alias through the current node's daemon RPC.
    /// Returns nil when the alias is not registered; throws on transport/node failure.
    func resolve(alias: String) async throws -> String? {
        let url = zanoNodeManager.node(blockchainType: .zano).url.appendingPathComponent("json_rpc")

        let parameters: [String: Any] = [
            "id": 0,
            "jsonrpc": "2.0",
            "method": "get_alias_details",
            "params": ["alias": alias],
        ]

        let json = try await networkManager.fetchJson(url: url, method: .post, parameters: parameters, encoding: JSONEncoding.default)

        guard let response = json as? [String: Any],
              let result = response["result"] as? [String: Any],
              result["status"] as? String == "OK",
              let details = result["alias_details"] as? [String: Any],
              let address = details["address"] as? String, !address.isEmpty
        else {
            return nil
        }

        return address
    }
}
