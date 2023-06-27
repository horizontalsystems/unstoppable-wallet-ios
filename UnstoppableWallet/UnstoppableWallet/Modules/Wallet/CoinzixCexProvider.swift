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
            "1INCH": "1inch",
            "AAVE": "aave",
            "ADA": "cardano",
            "ALGO": "algorand",
            "AMP": "amp-token",
            "APE": "apecoin-ape",
            "ATOM": "cosmos",
            "AVAX": "avalanche-2",
            "AXS": "axie-infinity",
            "BAKE": "bakerytoken",
            "BCH": "bitcoin-cash",
            "BNB": "binancecoin",
            "BTC": "bitcoin",
            "BUSD": "binance-usd",
            "CAKE": "pancakeswap-token",
            "CHZ": "chiliz",
            "COMP": "compound-governance-token",
            "DENT": "dent",
            "DOGE": "dogecoin",
            "DOT": "polkadot",
            "EGLD": "elrond-erd-2",
            "ENJ": "enjincoin",
            "EOS": "eos",
            "ETC": "ethereum-classic",
            "ETH": "ethereum",
            "FIL": "filecoin",
            "FLOKI": "floki",
            "FTM": "fantom",
            "GMT": "stepn",
            "GRT": "the-graph",
            "HOT": "holotoken",
            "IOTA": "iota",
            "LINK": "chainlink",
            "LTC": "litecoin",
            "LUNA": "terra-luna-2",
            "LUNC": "terra-luna",
            "MANA": "decentraland",
            "MATIC": "matic-network",
            "MKR": "maker",
            "NEAR": "near",
            "ONE": "harmony",
            "PEPE": "pepe",
            "QNT": "quant-network",
            "QTUM": "qtum",
            "REEF": "reef",
            "RNDR": "render-token",
            "RUNE": "thorchain",
            "SAND": "the-sandbox",
            "SC": "siacoin",
            "SHIB": "shiba-inu",
            "SOL": "solana",
            "SUI": "sui",
            "SUSHI": "sushi",
            "TFUEL": "theta-fuel",
            "THETA": "theta-token",
            "TRX": "tron",
            "UNI": "uniswap",
            "USDT": "tether",
            "VET": "vechain",
            "WIN": "wink",
            "WISTA": "wistaverse",
            "XLM": "stellar",
            "XMR": "monero",
            "XRP": "ripple",
            "XTZ": "tezos",
            "XVG": "verge",
            "YFI": "yearn-finance",
            "ZIL": "zilliqa",
            "ZIX": "coinzix-token",
        ]
    }

    private func blockchainUidMap() async throws -> [String: String] {
        [
            "BSC": "binance-smart-chain",
            "ETH": "ethereum",
            "BNB": "binancecoin",
            "MATIC": "polygon-pos",
            "SOL": "solana",
            "TRX": "tron",
        ]
    }

    private func fetch<T: ImmutableMappable>(path: String, parameters: Parameters = [:]) async throws -> T {
        var parameters = parameters

        let requestId = String(Int(Date().timeIntervalSince1970))
        parameters["request_id"] = requestId

        let parametersSignature = parameters.keys.sorted().compactMap { parameters[$0].map { "\($0)" } }.joined(separator: "")

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
        let blockchainUidMap = try await blockchainUidMap()

        return response.balances
                .map { balanceResponse in
                    let assetId = balanceResponse.currencyIso3
                    let balance = Decimal(sign: .plus, exponent: -8, significand: balanceResponse.balance)
                    let balanceAvailable = Decimal(sign: .plus, exponent: -8, significand: balanceResponse.balanceAvailable)
                    let depositEnabled = balanceResponse.currencyRefill == 1
                    let withdrawEnabled = balanceResponse.currencyWithdraw == 1

                    return CexAssetResponse(
                            id: assetId,
                            name: balanceResponse.currencyName,
                            freeBalance: balanceAvailable,
                            lockedBalance: balance - balanceAvailable,
                            depositEnabled: depositEnabled,
                            withdrawEnabled: withdrawEnabled,
                            networks: balanceResponse.networks.values.map { network in
                                CexNetworkRaw(
                                        network: network,
                                        name: network,
                                        isDefault: false,
                                        depositEnabled: depositEnabled,
                                        withdrawEnabled: withdrawEnabled,
                                        blockchainUid: blockchainUidMap[network]
                                )
                            },
                            coinUid: coinUidMap[assetId]
                    )
                }
    }

    func deposit(id: String, network: String?) async throws -> (String, String?) {
        var parameters: Parameters = [
            "iso": id,
            "new": 0
        ]

        if let network {
            parameters["network"] = network
        }

        let response: GetAddressResponse = try await fetch(path: "/v1/private/get-address", parameters: parameters)

        guard response.status else {
            throw RequestError.negativeStatusForDeposit
        }

        if let address = response.address {
            return (address, response.memo)
        } else if let account = response.account {
            return (account, response.memo)
        } else {
            throw RequestError.invalidDepositResponse
        }
    }

    func withdraw(id: String, network: String?, address: String, amount: Decimal) async throws -> String {
        var parameters: Parameters = [
            "iso": id,
            "to_address": address,
            "amount": amount
        ]

        if let network {
            parameters["network"] = network
        }

        let response: WithdrawResponse = try await fetch(path: "/v1/withdraw", parameters: parameters)

        guard response.status else {
            throw RequestError.negativeStatusForWithdraw
        }

        return String(response.id)
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
            let networks: [String: String]
            let balance: Decimal
            let balanceAvailable: Decimal

            init(map: Map) throws {
                currencyIso3 = try map.value("currency.iso3")
                currencyName = try map.value("currency.name")
                currencyRefill = try map.value("currency.refill")
                currencyWithdraw = try map.value("currency.withdraw")
                networks = (try? map.value("currency.networks")) ?? [:]
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

    private struct GetAddressResponse: ImmutableMappable {
        let status: Bool
        let address: String?
        let account: String?
        let memo: String?

        init(map: Map) throws {
            status = try map.value("status")
            address = try? map.value("data.address")
            account = try? map.value("data.account")
            memo = try? map.value("data.memo")
        }
    }

    private struct WithdrawResponse: ImmutableMappable {
        let status: Bool
        let id: Int

        init(map: Map) throws {
            status = try map.value("status")
            id = try map.value("data.id")
        }
    }

    enum RequestError: Error {
        case invalidSignatureData
        case negativeStatusForDeposit
        case invalidDepositResponse
        case negativeStatusForWithdraw
    }

    enum LoginError: Error {
        case loginFailed(message: String)
    }

}
