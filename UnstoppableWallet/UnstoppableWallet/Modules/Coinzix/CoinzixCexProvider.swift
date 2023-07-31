import Foundation
import HsCryptoKit
import Alamofire
import ObjectMapper
import MarketKit
import HsToolKit

class CoinzixCexProvider {
    private static let baseUrl = "https://api.coinzix.com"
    private static let nativeNetworkId = "NATIVE"
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
            "ARB": "arbitrum",
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
            "GALA": "gala",
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

    private func networkTypeToBlockchainUidMap() async throws -> [Int: String] {
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

    private func isoToBlockchainUidMap() async throws -> [String: String] {
        [
            "ADA": "cardano",
            "ALGO": "algorand",
            "ATOM": "cosmos",
            "BCH": "bitcoin-cash",
            "BTC": "bitcoin",
            "DOGE": "dogecoin",
            "DOT": "polkadot",
            "EGLD": "elrond-erd-2",
            "EOS": "eos",
            "ETH": "ethereum",
            "LTC": "litecoin",
            "LUNA": "terra-luna-2",
            "LUNC": "terra-luna",
            "MATIC": "polygon-pos",
            "ONE": "harmony",
            "QTUM": "qtum",
            "RUNE": "thorchain",
            "SC": "siacoin",
            "SOL": "solana",
            "SUI": "sui",
            "THETA": "theta-token",
            "TRX": "tron",
            "VET": "vechain",
            "XLM": "stellar",
            "XMR": "monero",
            "XRP": "ripple",
            "ZIL": "zilliqa",
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

        do {
            return try await networkManager.fetch(
                url: Self.baseUrl + path,
                method: .post,
                parameters: parameters,
                encoding: JSONEncoding.default,
                headers: headers
            )
        } catch let responseError as HsToolKit.NetworkManager.ResponseError {
            guard let json = responseError.json as? [String: Any] else {
                throw responseError
            }

            var message: String?

            if let error = json["error"] as? String? {
                message = error
            }

            if let errors = json["error"] as? [String] {
                message = errors.first
            }

            throw RequestError.invalidRequest(message: message ?? "Unknown error")
        }
    }

    private func fetch<T: ImmutableMappable>(path: String, parameters: Parameters = [:]) async throws -> T {
        try await networkManager.fetch(url: Self.baseUrl + path, method: .post, parameters: parameters, encoding: JSONEncoding.default)
    }

}

extension CoinzixCexProvider: ICexAssetProvider {

    func assets() async throws -> [CexAssetResponse] {
        async let configRequest: ConfigResponse = try fetch(path: "/api/default/config")
        async let balancesRequest: BalancesResponse = try signedFetch(path: "/v1/private/balances")

        let (configResponse, balancesResponse) = try await (configRequest, balancesRequest)

        let coinUidMap = try await coinUidMap()
        let networkTypeToBlockchainUidMap = try await networkTypeToBlockchainUidMap()
        let isoToBlockchainUidMap = try await isoToBlockchainUidMap()

        let ignoredIds = configResponse.demoCurrencies.values

        return balancesResponse.items
                .compactMap { item in
                    let assetId = item.currencyIso3

                    guard !ignoredIds.contains(assetId) else {
                        return nil
                    }

                    let isFiat = configResponse.fiatCurrencies.contains(assetId)

                    let balance = Decimal(sign: .plus, exponent: -8, significand: item.balance)
                    let balanceAvailable = Decimal(sign: .plus, exponent: -8, significand: item.balanceAvailable)
                    let depositEnabled = !isFiat && configResponse.depositCurrencies.contains(assetId)
                    let withdrawEnabled = !isFiat && configResponse.withdrawCurrencies.contains(assetId)

                    return CexAssetResponse(
                            id: assetId,
                            name: item.currencyName,
                            freeBalance: balanceAvailable,
                            lockedBalance: balance - balanceAvailable,
                            depositEnabled: depositEnabled,
                            withdrawEnabled: withdrawEnabled,
                            depositNetworks: configResponse.depositNetworks(id: assetId).enumerated().compactMap { index, network in
                                var networkId: String?

                                if network.networkType == 0 {
                                    networkId = Self.nativeNetworkId
                                } else {
                                    networkId = item.networks[String(network.networkType)]
                                }

                                guard let networkId else {
                                    return nil
                                }

                                return CexDepositNetworkRaw(
                                        id: networkId,
                                        name: networkId,
                                        isDefault: index == 0,
                                        enabled: depositEnabled,
                                        minAmount: network.minRefill,
                                        blockchainUid: network.networkType == 0 ? isoToBlockchainUidMap[assetId] : networkTypeToBlockchainUidMap[network.networkType]
                                )
                            },
                            withdrawNetworks: configResponse.withdrawNetworks(id: assetId).enumerated().compactMap { index, network in
                                var networkId: String?

                                if network.networkType == 0 {
                                    networkId = Self.nativeNetworkId
                                } else {
                                    networkId = item.networks[String(network.networkType)]
                                }

                                guard let networkId else {
                                    return nil
                                }

                                return CexWithdrawNetworkRaw(
                                        id: networkId,
                                        name: networkId,
                                        isDefault: index == 0,
                                        enabled: withdrawEnabled,
                                        minAmount: network.minWithdraw,
                                        maxAmount: network.maxWithdraw,
                                        fixedFee: network.fixed,
                                        feePercent: network.percent,
                                        minFee: network.minCommission,
                                        blockchainUid: network.networkType == 0 ? isoToBlockchainUidMap[assetId] : networkTypeToBlockchainUidMap[network.networkType]
                                )
                            },
                            coinUid: coinUidMap[assetId]
                    )
                }
    }

}

extension CoinzixCexProvider: ICexDepositProvider {

    func deposit(id: String, network: String?) async throws -> (String, String?) {
        var parameters: Parameters = [
            "iso": id
        ]

        if let network, network != Self.nativeNetworkId {
            parameters["network"] = network
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
            throw RequestError.invalidResponse
        }
    }

}

extension CoinzixCexProvider {

    func withdraw(id: String, network: String?, address: String, amount: Decimal, feeFromAmount: Bool?) async throws -> (String, [TwoFactorType]) {
        var parameters: Parameters = [
            "iso": id,
            "to_address": address,
            "amount": amount,
            "fee_from_amount": (feeFromAmount ?? false) ? 1 : 0
        ]

        if let network, network != Self.nativeNetworkId {
            parameters["network"] = network
        }

        let response: WithdrawResponse = try await signedFetch(path: "/v1/withdraw", parameters: parameters)

        guard response.status else {
            throw RequestError.negativeStatus
        }

        let twoFactorTypes = response.step?.compactMap { TwoFactorType.init(rawValue: $0) }

        return (String(response.id), twoFactorTypes ?? [])
    }

    func confirmWithdraw(id: Int, emailPin: String?, googlePin: String?) async throws {
        var parameters: Parameters = [
            "id": id,
        ]

        if let emailPin {
            parameters["email_pin"] = emailPin
        }

        if let googlePin {
            parameters["google_pin"] = googlePin
        }

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

    static func login(username: String, password: String, networkManager: NetworkManager) async throws -> LoginData {
        let parameters: Parameters = [
            "username": username,
            "password": password,
        ]

        let response: LoginResponse = try await networkManager.fetch(
            url: baseUrl + "/api/user/init-app",
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default
        )

        if response.status {
            if let token = response.token, let secret = response.secret, let twoFactorTypeRaw = response.twoFactorTypeRaw, let twoFactorType = TwoFactorType(rawValue: twoFactorTypeRaw) {
                return LoginData(token: token, secret: secret, twoFactorType: twoFactorType)
            }
        } else {
            if let leftAttempts = response.leftAttempts {
                throw LoginError.invalidCredentials(attemptsLeft: leftAttempts)
            }

            if let timeExpire = response.timeExpire {
                throw LoginError.tooManyAttempts(unlockDate: Date(timeIntervalSince1970: TimeInterval(timeExpire)))
            }
        }

        throw LoginError.unknown(message: response.errors.map { $0.joined(separator: "\n") } ?? "Unknown error")
    }

    static func validateCode(code: String, token: String, networkManager: NetworkManager) async throws {
        let parameters: Parameters = [
            "code": code,
            "login_token": token
        ]

        let response: StatusResponse = try await networkManager.fetch(
                url: baseUrl + "/api/user/validate-code",
                method: .post,
                parameters: parameters,
                encoding: JSONEncoding.default
        )

        guard response.status else {
            if let errors = response.errors {
                throw VerifyError(messages: errors)
            }

            throw RequestError.negativeStatus
        }
    }

    static func resendPin(token: String, networkManager: NetworkManager) async throws {
        let parameters: Parameters = [
            "login_token": token
        ]

        let response: StatusResponse = try await networkManager.fetch(
                url: baseUrl + "/api/user/send-two-fa",
                method: .post,
                parameters: parameters,
                encoding: JSONEncoding.default
        )

        guard response.status else {
            if let errors = response.errors {
                throw VerifyError(messages: errors)
            }

            throw RequestError.negativeStatus
        }
    }

}

extension CoinzixCexProvider {

    struct LoginData {
        let token: String
        let secret: String
        let twoFactorType: TwoFactorType
    }

    enum LoginError: LocalizedError {
        case invalidCredentials(attemptsLeft: Int)
        case tooManyAttempts(unlockDate: Date)
        case unknown(message: String)

        var errorDescription: String? {
            switch self {
            case .invalidCredentials(let attemptsLeft): return "Invalid login credentials. Attempts left: \(attemptsLeft)."
            case .tooManyAttempts(let unlockDate): return "Too many invalid login attempts were made. Login is locked until \(DateHelper.instance.formatFullTime(from: unlockDate))."
            case .unknown(let message): return message
            }
        }
    }

    struct VerifyError: LocalizedError {
        let messages: [String]

        var errorDescription: String? {
            messages.joined(separator: "\n")
        }
    }

    enum TwoFactorType: Int {
        case email = 1
        case authenticator = 2
    }

    private struct ConfigResponse: ImmutableMappable {
        let withdrawCurrencies: [String]
        let depositCurrencies: [String]
        let withdrawNetworks: [String: WithdrawNetwork]
        let depositNetworks: [String: DepositNetwork]
        let demoCurrencies: [String: String]
        let fiatCurrencies: [String]

        init(map: Map) throws {
            withdrawCurrencies = try map.value("data.currency_withdraw")
            depositCurrencies = try map.value("data.currency_deposit")
            withdrawNetworks = try map.value("data.commission")
            depositNetworks = try map.value("data.commission_refill")
            demoCurrencies = try map.value("data.demo_currency")
            fiatCurrencies = try map.value("data.fiat_currencies")
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
            let percent: Decimal
            let minCommission: Decimal
            let maxWithdraw: Decimal
            let minWithdraw: Decimal
            let networkType: Int
            let networks: [WithdrawNetwork]

            init(map: Map) throws {
                fixed = try map.value("fixed", using: Transform.doubleToDecimalTransform)
                percent = try map.value("percent", using: Transform.doubleToDecimalTransform)
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
            let networks: [String: String]

            init(map: Map) throws {
                currencyIso3 = try map.value("currency.iso3")
                currencyName = try map.value("currency.name")
                balance = try map.value("balance", using: Transform.doubleToDecimalTransform)
                balanceAvailable = try map.value("balance_available", using: Transform.doubleToDecimalTransform)
                networks = (try? map.value("currency.networks")) ?? [:]
            }
        }
    }

    private struct LoginResponse: ImmutableMappable {
        let status: Bool
        let token: String?
        let secret: String?
        let twoFactorTypeRaw: Int?
        let leftAttempts: Int?
        let timeExpire: Int?
        let errors: [String]?

        init(map: Map) throws {
            status = try map.value("status")
            token = try? map.value("token")
            secret = try? map.value("data.secret")
            twoFactorTypeRaw = try? map.value("data.required")
            leftAttempts = try? map.value("data.left_attempt")
            timeExpire = try? map.value("data.time_expire")
            errors = try? map.value("errors")
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
        let step: [Int]?

        init(map: Map) throws {
            status = try map.value("status")
            id = try map.value("data.id")
            step = try map.value("data.step")
        }
    }

    private struct StatusResponse: ImmutableMappable {
        let status: Bool
        let errors: [String]?

        init(map: Map) throws {
            status = try map.value("status")
            errors = try? map.value("errors")
        }
    }

    enum RequestError: LocalizedError {
        case invalidSignatureData
        case invalidResponse
        case negativeStatus
        case invalidRequest(message: String)

        public var errorDescription: String? {
            switch self {
                case .invalidSignatureData: return "Invalid signature data"
                case .invalidResponse: return "Invalid Response"
                case .negativeStatus: return "Request failed with unknown error"
                case .invalidRequest(let message): return message
            }
        }
    }

}
