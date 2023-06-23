import Foundation
import Crypto
import Alamofire
import ObjectMapper
import MarketKit
import HsToolKit

class BinanceCexProvider {
    private static let baseUrl = "https://api.binance.com"

    private let networkManager: NetworkManager
    private let apiKey: String
    private let secret: String

    init(networkManager: NetworkManager, apiKey: String, secret: String) {
        self.networkManager = networkManager
        self.apiKey = apiKey
        self.secret = secret
    }

    private func coinUidMap() async throws -> [String: String] {
        [
            "USDT": "tether",
            "BUSD": "binance-usd",
            "AGIX": "singularitynet",
            "SUSHI": "sushi",
            "GMT": "stepn",
            "CAKE": "pancakeswap-token",
            "ETH": "ethereum",
            "ETHW": "ethereum-pow-iou",
            "BTC": "bitcoin",
            "BNB": "binancecoin",
        ]
    }

    private func blockchainUidMap() async throws -> [String: String] {
        [
            "BSC": "binance-smart-chain",
            "ETH": "ethereum",
        ]
    }

    private static func signed(parameters: Parameters, apiKey: String, secret: String) throws -> (Parameters, HTTPHeaders) {
        var parameters = parameters

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        parameters["timestamp"] = timestamp

        let queryString = parameters.map { ($0, $1) }.sorted { $0.0 < $1.0 }.map { "\($0)=\($1)" }.joined(separator: "&")

        guard let queryStringData = queryString.data(using: .utf8) else {
            throw RequestError.invalidQueryString
        }

        guard let secretData = secret.data(using: .utf8) else {
            throw RequestError.invalidSecret
        }

        let symmetricKey = SymmetricKey(data: secretData)
        let signature = Data(HMAC<SHA256>.authenticationCode(for: queryStringData, using: symmetricKey))
        parameters["signature"] = Data(signature).hs.hex

        return (parameters, HTTPHeaders(["X-MBX-APIKEY": apiKey]))
    }

    private static func fetch<T: ImmutableMappable>(networkManager: NetworkManager, apiKey: String, secret: String, path: String, method: HTTPMethod = .get, parameters: Parameters = [:]) async throws -> T {
        let (parameters, headers) = try signed(parameters: parameters, apiKey: apiKey, secret: secret)
        return try await networkManager.fetch(url: baseUrl + path, method: method, parameters: parameters, headers: headers)
    }

    private static func fetch<T: ImmutableMappable>(networkManager: NetworkManager, apiKey: String, secret: String, path: String, method: HTTPMethod = .get, parameters: Parameters = [:]) async throws -> [T] {
        let (parameters, headers) = try signed(parameters: parameters, apiKey: apiKey, secret: secret)
        return try await networkManager.fetch(url: baseUrl + path, method: method, parameters: parameters, headers: headers)
    }

    private func fetch<T: ImmutableMappable>(path: String, method: HTTPMethod = .get, parameters: Parameters = [:]) async throws -> T {
        try await Self.fetch(networkManager: networkManager, apiKey: apiKey, secret: secret, path: path, method: method, parameters: parameters)
    }

    private func fetch<T: ImmutableMappable>(path: String, method: HTTPMethod = .get, parameters: Parameters = [:]) async throws -> [T] {
        try await Self.fetch(networkManager: networkManager, apiKey: apiKey, secret: secret, path: path, method: method, parameters: parameters)
    }

}

extension BinanceCexProvider: ICexProvider {

    func assets() async throws -> [CexAssetResponse] {
        let response: [AssetResponse] = try await fetch(path: "/sapi/v1/capital/config/getall")

        let coinUidMap = try await coinUidMap()
        let blockchainUidMap = try await blockchainUidMap()

        return response
                .map { asset in
                    CexAssetResponse(
                            id: asset.coin,
                            name: asset.name,
                            freeBalance: asset.free,
                            lockedBalance: asset.locked,
                            depositEnabled: asset.depositAllEnable,
                            withdrawEnabled: asset.withdrawAllEnable,
                            networks: asset.networks.map { network in
                                CexNetworkRaw(
                                        network: network.network,
                                        name: network.name,
                                        isDefault: network.isDefault,
                                        depositEnabled: network.depositEnable,
                                        withdrawEnabled: network.withdrawEnable,
                                        blockchainUid: blockchainUidMap[network.network]
                                )
                            },
                            coinUid: coinUidMap[asset.coin]
                    )
                }
    }

    func deposit(id: String, network: String?) async throws -> (String, String?) {
        var parameters: Parameters = [
            "coin": id
        ]

        if let network {
            parameters["network"] = network
        }

        let response: DepositResponse = try await fetch(path: "/sapi/v1/capital/deposit/address", parameters: parameters)
        return (response.address, response.tag.isEmpty ? nil : response.tag)
    }

    func withdraw(id: String, network: String, address: String, amount: Decimal) async throws -> String {
        let parameters: Parameters = [
            "coin": id,
            "network": network,
            "address": address,
            "amount": amount
        ]

        let response: WithdrawResponse = try await fetch(path: "/sapi/v1/capital/withdraw/apply", method: .post, parameters: parameters)
        return response.id
    }

}

extension BinanceCexProvider {

    static func validate(apiKey: String, secret: String, networkManager: NetworkManager) async throws {
        let _: [AssetResponse] = try await Self.fetch(networkManager: networkManager, apiKey: apiKey, secret: secret, path: "/sapi/v1/capital/config/getall")
    }

}

extension BinanceCexProvider {

    private struct AssetResponse: ImmutableMappable {
        let coin: String
        let name: String
        let free: Decimal
        let locked: Decimal
        let depositAllEnable: Bool
        let withdrawAllEnable: Bool
        let networks: [Network]

        init(map: Map) throws {
            coin = try map.value("coin")
            name = try map.value("name")
            free = try map.value("free", using: Transform.stringToDecimalTransform)
            locked = try map.value("locked", using: Transform.stringToDecimalTransform)
            depositAllEnable = try map.value("depositAllEnable")
            withdrawAllEnable = try map.value("withdrawAllEnable")
            networks = try map.value("networkList")
        }

        struct Network: ImmutableMappable {
            let network: String
            let name: String
            let isDefault: Bool
            let depositEnable: Bool
            let withdrawEnable: Bool

            init(map: Map) throws {
                network = try map.value("network")
                name = try map.value("name")
                isDefault = try map.value("isDefault")
                depositEnable = try map.value("depositEnable")
                withdrawEnable = try map.value("withdrawEnable")
            }
        }
    }

    private struct DepositResponse: ImmutableMappable {
        let address: String
        let tag: String

        init(map: Map) throws {
            address = try map.value("address")
            tag = try map.value("tag")
        }
    }

    private struct WithdrawResponse: ImmutableMappable {
        let id: String

        init(map: Map) throws {
            id = try map.value("id")
        }
    }

    enum RequestError: Error {
        case invalidSecret
        case invalidQueryString
    }

}
