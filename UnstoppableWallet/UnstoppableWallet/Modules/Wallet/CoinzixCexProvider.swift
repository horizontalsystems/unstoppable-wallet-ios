import Foundation
import HsCryptoKit
import Alamofire
import ObjectMapper
import MarketKit
import HsToolKit

class CoinzixCexProvider {
    private let baseUrl = "https://api.coinzix.com"

    private let networkManager: NetworkManager
    private let marketKit: MarketKit.Kit
    private let authToken: String
    private let secret: String

    init(networkManager: NetworkManager, marketKit: MarketKit.Kit, authToken: String, secret: String) {
        self.networkManager = networkManager
        self.marketKit = marketKit
        self.authToken = authToken
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

    private func fetch<T: ImmutableMappable>(path: String, parameters: Parameters = [:]) async throws -> T {
        var parameters = parameters

        let requestId = String(Int(Date().timeIntervalSince1970))
        parameters["request_id"] = requestId

        let parametersSignature = parameters.keys.sorted().compactMap { parameters[$0] as? String }.joined(separator: "")

        let signature = parametersSignature + secret

        guard let signatureData = signature.data(using: .utf8) else {
            throw RequestError.invalidSignatureData
        }

        let headers = HTTPHeaders([
            "login-token": authToken,
            "x-auth-sign": Crypto.sha256(signatureData).hs.hex
        ])

        return try await networkManager.fetch(
                url: baseUrl + path,
                method: .post,
                parameters: parameters,
                encoding: JSONEncoding.default,
                headers: headers
        )
    }

}

extension CoinzixCexProvider: ICexProvider {

    func balances() async throws -> [CexBalance] {
        let response: BalancesResponse = try await fetch(path: "/v1/private/balances")

        let map = try await coinUidMap()
        let coins = try marketKit.allCoins()
        var coinMap = [String: Coin]()
        coins.forEach { coinMap[$0.uid] = $0 }

        return response.balances
                .filter { $0.balance > 0 }
                .map { balanceResponse in
                    let assetId = balanceResponse.currencyIso3
                    let balance = Decimal(sign: .plus, exponent: -8, significand: balanceResponse.balance)
                    let balanceAvailable = Decimal(sign: .plus, exponent: -8, significand: balanceResponse.balanceAvailable)

                    return CexBalance(
                            asset: CexAsset(id: assetId, coin: map[assetId].flatMap { coinMap[$0] }),
                            free: balanceAvailable,
                            locked: balance - balanceAvailable
                    )
                }
    }

}

extension CoinzixCexProvider {

    private struct BalancesResponse: ImmutableMappable {
        let balances: [Balance]

        init(map: Map) throws {
            balances = try map.value("data.list")
        }

        struct Balance: ImmutableMappable {
            let currencyIso3: String
            let balance: Decimal
            let balanceAvailable: Decimal

            init(map: Map) throws {
                currencyIso3 = try map.value("currency.iso3")
                balance = try map.value("balance", using: Transform.doubleToDecimalTransform)
                balanceAvailable = try map.value("balance_available", using: Transform.doubleToDecimalTransform)
            }
        }
    }

    enum RequestError: Error {
        case invalidSignatureData
    }

}
