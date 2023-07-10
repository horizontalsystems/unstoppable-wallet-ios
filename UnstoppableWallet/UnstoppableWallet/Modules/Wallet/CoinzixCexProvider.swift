import Foundation
import HsCryptoKit
import Alamofire
import ObjectMapper
import MarketKit
import HsToolKit

class CoinzixCexProvider {
    private static let baseUrl = "https://api.coinzix.com"
    static let withdrawEmailPinResendTime: UInt64 = 5_000_000_000

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

    private func blockchainUidMap() async throws -> [Int: String] {
        [
            1: "ethereum",
            2: "tron",
            3: "binancecoin",
            4: "binance-smart-chain",
            6: "solana",
            8: "polygon-pos",
            9: "arbitrum-one",
        ]
    }

    private func signedFetch<T: ImmutableMappable>(path: String, parameters: Parameters = [:]) async throws -> T {
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

    private func fetch<T: ImmutableMappable>(path: String, parameters: Parameters = [:]) async throws -> T {
        try await networkManager.fetch(url: Self.baseUrl + path, method: .post, parameters: parameters, encoding: JSONEncoding.default)
    }

}

extension CoinzixCexProvider: ICexProvider {

    func assets() async throws -> [CexAssetResponse] {
        async let configRequest: ConfigResponse = try fetch(path: "/api/default/config")
        async let balancesRequest: BalancesResponse = try signedFetch(path: "/v1/private/balances")

        let (configResponse, balancesResponse) = try await (configRequest, balancesRequest)

        let coinUidMap = try await coinUidMap()
        let blockchainUidMap = try await blockchainUidMap()

        return balancesResponse.items
                .map { item in
                    let assetId = item.currencyIso3
                    let balance = Decimal(sign: .plus, exponent: -8, significand: item.balance)
                    let balanceAvailable = Decimal(sign: .plus, exponent: -8, significand: item.balanceAvailable)
                    let depositEnabled = configResponse.depositCurrencies.contains(assetId)
                    let withdrawEnabled = configResponse.withdrawCurrencies.contains(assetId)

                    return CexAssetResponse(
                            id: assetId,
                            name: item.currencyName,
                            freeBalance: balanceAvailable,
                            lockedBalance: balance - balanceAvailable,
                            depositEnabled: depositEnabled,
                            withdrawEnabled: withdrawEnabled,
                            depositNetworks: configResponse.depositNetworks(id: assetId).enumerated().map { index, network in
                                CexDepositNetworkRaw(
                                        id: String(network.networkType),
                                        name: network.networkType == 0 ? "Native" : String(network.networkType),
                                        isDefault: index == 0,
                                        enabled: depositEnabled,
                                        minAmount: network.minRefill,
                                        blockchainUid: blockchainUidMap[network.networkType]
                                )
                            },
                            withdrawNetworks: configResponse.withdrawNetworks(id: assetId).enumerated().map { index, network in
                                CexWithdrawNetworkRaw(
                                        id: String(network.networkType),
                                        name: network.networkType == 0 ? "Native" : String(network.networkType),
                                        isDefault: index == 0,
                                        enabled: withdrawEnabled,
                                        minAmount: network.minWithdraw,
                                        maxAmount: network.maxWithdraw,
                                        commission: network.fixed,
                                        blockchainUid: blockchainUidMap[network.networkType]
                                )
                            },
                            coinUid: coinUidMap[assetId]
                    )
                }
    }

    func deposit(id: String, network: String?) async throws -> (String, String?) {
        var parameters: Parameters = [
            "iso": id
        ]

        if let network, let networkType = Int(network) {
            parameters["network_type"] = networkType
        }

        let response: GetAddressResponse = try await signedFetch(path: "/v1/private/get-address", parameters: parameters)

        guard response.status else {
            throw RequestError.negativeStatus
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

        let response: WithdrawResponse = try await signedFetch(path: "/v1/withdraw", parameters: parameters)

        guard response.status else {
            throw RequestError.negativeStatus
        }

        return String(response.id)
    }

    func confirmWithdraw(id: Int, emailPin: String, googlePin: String) async throws {
        let parameters: Parameters = [
            "id": id,
            "email_pin": emailPin,
            "google_pin": googlePin
        ]

        let response: StatusResponse = try await signedFetch(path: "/v1/withdraw/confirm-code", parameters: parameters)

        guard response.status else {
            throw RequestError.negativeStatus
        }
    }

    func sendWithdrawPin(id: Int) async throws {
        let parameters: Parameters = [
            "id": id
        ]

        let response: StatusResponse = try await signedFetch(path: "/v1/withdraw/send-pin", parameters: parameters)

        guard response.status else {
            throw RequestError.negativeStatus
        }
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

    private struct ConfigResponse: ImmutableMappable {
        let withdrawCurrencies: [String]
        let depositCurrencies: [String]
        let withdrawNetworks: [String: WithdrawNetwork]
        let depositNetworks: [String: DepositNetwork]

        init(map: Map) throws {
            withdrawCurrencies = try map.value("data.currency_withdraw")
            depositCurrencies = try map.value("data.currency_deposit")
            withdrawNetworks = try map.value("data.commission")
            depositNetworks = try map.value("data.commission_refill")
        }

        func withdrawNetworks(id: String) -> [WithdrawNetwork] {
            guard let network = withdrawNetworks[id] else {
                return []
            }

            return [network] + network.networks
        }

        func depositNetworks(id: String) -> [DepositNetwork] {
            guard let network = depositNetworks[id] else {
                return []
            }

            return [network] + network.networks
        }

        struct WithdrawNetwork: ImmutableMappable {
            let fixed: Decimal
            let minCommission: Decimal
            let maxWithdraw: Decimal
            let minWithdraw: Decimal
            let networkType: Int
            let networks: [WithdrawNetwork]

            init(map: Map) throws {
                fixed = try map.value("fixed", using: Transform.doubleToDecimalTransform)
                minCommission = try map.value("min_commission", using: Transform.doubleToDecimalTransform)
                maxWithdraw = try map.value("max_withdraw", using: Transform.doubleToDecimalTransform)
                minWithdraw = try map.value("min_withdraw", using: Transform.doubleToDecimalTransform)
                networkType = try map.value("network_type")
                networks = (try? map.value("networks")) ?? []
            }
        }

        struct DepositNetwork: ImmutableMappable {
            let fixed: Decimal
            let minCommission: Decimal
            let minRefill: Decimal
            let networkType: Int
            let networks: [DepositNetwork]

            init(map: Map) throws {
                fixed = try map.value("fixed", using: Transform.doubleToDecimalTransform)
                minCommission = try map.value("min_commission", using: Transform.doubleToDecimalTransform)
                minRefill = try map.value("min_refill", using: Transform.doubleToDecimalTransform)
                networkType = try map.value("network_type")
                networks = (try? map.value("networks")) ?? []
            }
        }
    }

    private struct BalancesResponse: ImmutableMappable {
        let items: [Item]

        init(map: Map) throws {
            items = try map.value("data.list")
        }

        struct Item: ImmutableMappable {
            let currencyIso3: String
            let currencyName: String
            let balance: Decimal
            let balanceAvailable: Decimal

            init(map: Map) throws {
                currencyIso3 = try map.value("currency.iso3")
                currencyName = try map.value("currency.name")
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

    private struct StatusResponse: ImmutableMappable {
        let status: Bool

        init(map: Map) throws {
            status = try map.value("status")
        }
    }

    enum RequestError: Error {
        case invalidSignatureData
        case invalidDepositResponse
        case negativeStatus
    }

    enum LoginError: Error {
        case loginFailed(message: String)
    }

}
