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

    private static func fetch<T: ImmutableMappable>(networkManager: NetworkManager, apiKey: String, secret: String, path: String, parameters: Parameters = [:]) async throws -> T {
        var parameters = parameters

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        parameters["timestamp"] = timestamp

        let queryString = parameters.map { "\($0)=\($1)" }.joined(separator: "&")

        guard let queryStringData = queryString.data(using: .utf8) else {
            throw RequestError.invalidQueryString
        }

        guard let secretData = secret.data(using: .utf8) else {
            throw RequestError.invalidSecret
        }

        let symmetricKey = SymmetricKey(data: secretData)
        let signature = Data(HMAC<SHA256>.authenticationCode(for: queryStringData, using: symmetricKey))
        parameters["signature"] = Data(signature).hs.hex

        let headers = HTTPHeaders(["X-MBX-APIKEY": apiKey])
        return try await networkManager.fetch(url: baseUrl + path, parameters: parameters, headers: headers)
    }

    private func fetch<T: ImmutableMappable>(path: String, parameters: Parameters = [:]) async throws -> T {
        try await Self.fetch(networkManager: networkManager, apiKey: apiKey, secret: secret, path: path, parameters: parameters)
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

    enum RequestError: Error {
        case invalidSecret
        case invalidQueryString
    }

}
