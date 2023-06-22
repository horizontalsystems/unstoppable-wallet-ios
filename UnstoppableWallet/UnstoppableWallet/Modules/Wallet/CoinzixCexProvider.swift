import Foundation
import HsCryptoKit
import Alamofire
import ObjectMapper
import MarketKit
import HsToolKit

class CoinzixCexProvider {
    private static let baseUrl = "https://api.coinzix.com"

    private let networkManager: NetworkManager
    private let authToken: String
    private let secret: String

    init(networkManager: NetworkManager, authToken: String, secret: String) {
        self.networkManager = networkManager
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
                url: Self.baseUrl + path,
                method: .post,
                parameters: parameters,
                encoding: JSONEncoding.default,
                headers: headers
        )
    }

}

extension CoinzixCexProvider: ICexProvider {

    func assets() async throws -> [CexAssetResponse] {
        let response: BalancesResponse = try await fetch(path: "/v1/private/balances")

        let coinUidMap = try await coinUidMap()

        return response.balances
                .map { balanceResponse in
                    let assetId = balanceResponse.currencyIso3
                    let balance = Decimal(sign: .plus, exponent: -8, significand: balanceResponse.balance)
                    let balanceAvailable = Decimal(sign: .plus, exponent: -8, significand: balanceResponse.balanceAvailable)

                    return CexAssetResponse(
                            id: assetId,
                            name: balanceResponse.currencyName,
                            freeBalance: balanceAvailable,
                            lockedBalance: balance - balanceAvailable,
                            depositEnabled: balanceResponse.currencyRefill == 1,
                            withdrawEnabled: balanceResponse.currencyWithdraw == 1,
                            networks: [], // todo
                            coinUid: coinUidMap[assetId]
                    )
                }
    }

    func deposit(id: String, network: String?) async throws -> String {
        fatalError("deposit(cexAsset:network:) has not been implemented")
    }

    func withdraw(id: String, network: String, address: String, amount: Decimal) async throws -> String {
        fatalError("withdraw(cexAsset:network:address:amount:) has not been implemented")
    }

}

extension CoinzixCexProvider {

    static func login(username: String, password: String, captchaToken: String, networkManager: NetworkManager) async throws -> (String, String) {
        let parameters: Parameters = [
            "username": username,
            "password": password,
            "g-recaptcha-response": captchaToken
        ]

        let response: LoginResult = try await networkManager.fetch(
            url: baseUrl + "/api/user/login",
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default
        )

        guard let secret = response.secret, let token = response.token,
              response.status == true else {
            throw LoginError.loginFailed(message: response.message ?? response.requestError ?? "")
        }

        return (secret, token)
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
            let currencyName: String
            let currencyRefill: Int
            let currencyWithdraw: Int
            let balance: Decimal
            let balanceAvailable: Decimal

            init(map: Map) throws {
                currencyIso3 = try map.value("currency.iso3")
                currencyName = try map.value("currency.name")
                currencyRefill = try map.value("currency.refill")
                currencyWithdraw = try map.value("currency.withdraw")
                balance = try map.value("balance", using: Transform.doubleToDecimalTransform)
                balanceAvailable = try map.value("balance_available", using: Transform.doubleToDecimalTransform)
            }
        }
    }

    private struct LoginResult: ImmutableMappable {
        let status: Bool
        let message: String?
        let requestError: String?
        let secret: String?
        let token: String?

        init(map: Map) throws {
            status = try map.value("status")
            message = try map.value("message")
            requestError = try map.value("errors.request")
            secret = try map.value("data.secret")
            token = try map.value("token")
        }
    }

    enum RequestError: Error {
        case invalidSignatureData
    }

    enum LoginError: Error {
        case loginFailed(message: String)
    }

}
