import Alamofire
import Foundation
import HsToolKit
import MarketKit
import ZanoKit

class AddZanoTokenBlockchainService {
    private static let assetIdRegex = try! NSRegularExpression(pattern: "^[0-9a-f]{64}$")

    private let blockchain: Blockchain
    private let networkManager: NetworkManager
    private let zanoNodeManager: ZanoNodeManager

    init(blockchain: Blockchain, networkManager: NetworkManager, zanoNodeManager: ZanoNodeManager) {
        self.blockchain = blockchain
        self.networkManager = networkManager
        self.zanoNodeManager = zanoNodeManager
    }

    private func normalized(reference: String) -> String {
        reference.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

extension AddZanoTokenBlockchainService: IAddTokenBlockchainService {
    var placeholder: String {
        "add_token.input_placeholder.asset_id".localized
    }

    func validate(reference: String) throws {
        let value = normalized(reference: reference)
        let range = NSRange(value.startIndex..., in: value)

        guard Self.assetIdRegex.firstMatch(in: value, range: range) != nil, value != ZanoAssetId else {
            throw TokenError.invalidAssetId
        }
    }

    func tokenQuery(reference: String) -> TokenQuery {
        TokenQuery(blockchainType: blockchain.type, tokenType: .zanoAsset(id: normalized(reference: reference)))
    }

    func token(reference: String) async throws -> Token {
        let assetId = normalized(reference: reference)
        let url = zanoNodeManager.node(blockchainType: .zano).url.appendingPathComponent("json_rpc")

        let parameters: [String: Any] = [
            "id": 0,
            "jsonrpc": "2.0",
            "method": "get_asset_info",
            "params": ["asset_id": assetId],
        ]

        let json = try await networkManager.fetchJson(url: url, method: .post, parameters: parameters, encoding: JSONEncoding.default)

        guard let response = json as? [String: Any],
              let result = response["result"] as? [String: Any],
              result["status"] as? String == "OK",
              let descriptor = result["asset_descriptor"] as? [String: Any],
              let ticker = descriptor["ticker"] as? String,
              let fullName = descriptor["full_name"] as? String,
              // No fallback: decimals drive atomic-unit conversion in ZanoAdapter, so a
              // guessed value would corrupt balances and send amounts. 0...255 is the
              // protocol range of decimal_point.
              let decimals = descriptor["decimal_point"] as? Int,
              (0 ... 255).contains(decimals)
        else {
            throw TokenError.notFound(blockchainName: blockchain.name)
        }

        let tokenQuery = tokenQuery(reference: reference)

        return Token(
            coin: Coin(uid: tokenQuery.customCoinUid, name: fullName, code: ticker),
            blockchain: blockchain,
            type: tokenQuery.tokenType,
            decimals: decimals
        )
    }
}

extension AddZanoTokenBlockchainService {
    enum TokenError: LocalizedError {
        case invalidAssetId
        case notFound(blockchainName: String)

        var errorDescription: String? {
            switch self {
            case .invalidAssetId: return "add_token.invalid_asset_id".localized
            case let .notFound(blockchainName): return "add_token.contract_address_not_found".localized(blockchainName)
            }
        }
    }
}
