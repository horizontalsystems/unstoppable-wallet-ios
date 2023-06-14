import Foundation
import Crypto
import Alamofire
import ObjectMapper
import MarketKit
import HsToolKit

class BinanceCexProvider {
    private static let baseUrl = "https://api.binance.com"

    private let networkManager: NetworkManager
    private let marketKit: MarketKit.Kit
    private let apiKey: String
    private let secret: String

    init(networkManager: NetworkManager, marketKit: MarketKit.Kit, apiKey: String, secret: String) {
        self.networkManager = networkManager
        self.marketKit = marketKit
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

    func balances() async throws -> [CexBalance] {
        let response: AccountResponse = try await fetch(path: "/api/v3/account")

        let map = try await coinUidMap()
        let coins = try marketKit.allCoins()
        var coinMap = [String: Coin]()
        coins.forEach { coinMap[$0.uid] = $0 }

        return response.balances
                .filter { $0.free > 0 || $0.locked > 0 }
                .map { balance in
                    CexBalance(
                            asset: CexAsset(id: balance.asset, coin: map[balance.asset].flatMap { coinMap[$0] }),
                            free: balance.free,
                            locked: balance.locked
                    )
                }
    }

    func allAssetInfos() async throws -> [CexAssetInfo] {
        let response: [AssetResponse] = try await fetch(path: "/sapi/v1/capital/config/getall")

        let coinUidMap = try await coinUidMap()
        let coins = try marketKit.allCoins()
        var coinMap = [String: Coin]()
        coins.forEach { coinMap[$0.uid] = $0 }

        let blockchainUidMap = try await blockchainUidMap()
        let blockchains: [Blockchain] = [] // todo
        var blockchainMap = [String: Blockchain]()
        blockchains.forEach { blockchainMap[$0.uid] = $0 }

        return response
                .map { asset in
                    CexAssetInfo(
                            asset: CexAsset(id: asset.coin, coin: coinUidMap[asset.coin].flatMap { coinMap[$0] }),
                            networks: asset.networks.map { network in
                                CexNetwork(
                                        network: network.network,
                                        name: network.name,
                                        isDefault: network.isDefault,
                                        depositEnabled: network.depositEnable,
                                        withdrawEnabled: network.withdrawEnable,
                                        blockchain: blockchainUidMap[network.network].flatMap { blockchainMap[$0] }
                                )
                            }
                    )
                }
    }

    func deposit(cexAsset: CexAsset, network: String?) async throws -> String {
        var parameters: Parameters = [
            "coin": cexAsset.id
        ]

        if let network {
            parameters["network"] = network
        }

        let response: DepositResponse = try await fetch(path: "/sapi/v1/capital/deposit/address", parameters: parameters)
        return response.address
    }

    func withdraw(cexAsset: CexAsset, network: String, address: String, amount: Decimal) async throws -> String {
        let parameters: Parameters = [
            "coin": cexAsset.id,
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
        let _: AccountResponse = try await Self.fetch(networkManager: networkManager, apiKey: apiKey, secret: secret, path: "/api/v3/account")
    }

}

extension BinanceCexProvider {

    private struct AccountResponse: ImmutableMappable {
        let balances: [Balance]

        init(map: Map) throws {
            balances = try map.value("balances")
        }

        struct Balance: ImmutableMappable {
            let asset: String
            let free: Decimal
            let locked: Decimal

            init(map: Map) throws {
                asset = try map.value("asset")
                free = try map.value("free", using: Transform.stringToDecimalTransform)
                locked = try map.value("locked", using: Transform.stringToDecimalTransform)
            }
        }
    }

    private struct AssetResponse: ImmutableMappable {
        let coin: String
        let networks: [Network]

        init(map: Map) throws {
            coin = try map.value("coin")
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

        init(map: Map) throws {
            address = try map.value("address")
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
