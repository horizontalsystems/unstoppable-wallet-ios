import Alamofire
import Foundation
import HsToolKit
import MarketKit
import ObjectMapper

class UnstoppableProvider {
    private let baseUrl = "https://swap-api.unstoppable.money/"
    private let headers: HTTPHeaders?
    private let networkManager: NetworkManager

    init(apiKey: String?, networkManager: NetworkManager) {
        headers = HTTPHeaders([HTTPHeader(name: "x-api-key", value: apiKey ?? "")])
        self.networkManager = networkManager
    }

    func providers() async throws -> ProvidersResponse {
        let json = try await networkManager.fetchJson(
            url: "\(baseUrl)providers",
            method: .get,
            headers: headers
        )

        guard let array = json as? [[String: Any]] else {
            throw ResponseError.invalidJson
        }

        let providers = try array.map { try Provider(JSON: $0) }
        return ProvidersResponse(providers: providers)
    }

    func tokens(provider: String) async throws -> TokensResponse {
        let json = try await networkManager.fetchJson(
            url: "\(baseUrl)tokens",
            method: .get,
            parameters: ["provider": provider],
            headers: headers
        )

        guard let map = json as? [String: Any] else {
            throw ResponseError.invalidJson
        }

        return try TokensResponse(JSON: map)
    }

    func quote(request: QuoteRequest) async throws -> QuoteResponse {
        var parameters: [String: Any] = [
            "sellAsset": request.sellAsset,
            "buyAsset": request.buyAsset,
            "sellAmount": request.sellAmount,
            "slippage": request.slippage,
            "destinationAddress": request.destinationAddress,
            "providers": Array(request.providers),
            "includeTx": request.includeTx,
        ]

        if let sourceAddress = request.sourceAddress {
            parameters["sourceAddress"] = sourceAddress
        }

        return try await networkManager.fetch(url: "\(baseUrl)quote", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
    }
}

extension UnstoppableProvider {
    struct QuoteRequest {
        let sellAsset: String
        let buyAsset: String
        let sellAmount: String
        let providers: Set<String>
        let slippage: Int
        let destinationAddress: String
        let sourceAddress: String?
        let includeTx: Bool
    }

    enum ResponseError: Error {
        case invalidJson
    }

    struct ProvidersResponse {
        let providers: [Provider]
    }

    struct TokensResponse: ImmutableMappable {
        let tokens: [UnstoppableToken]

        init(map: Map) throws {
            tokens = try map.value("tokens")
        }
    }

    struct QuoteResponse: ImmutableMappable {
        let routes: [QuoteRoute]

        init(map: Map) throws {
            routes = try map.value("routes")
        }
    }

    struct Provider: ImmutableMappable {
        let provider: String

        init(map: Map) throws {
            provider = try map.value("provider")
        }
    }

    struct UnstoppableToken: ImmutableMappable {
        let chain: String
        let chainId: String
        let address: String?
        let identifier: String

        init(map: Map) throws {
            chain = try map.value("chain")
            chainId = try map.value("chainId")
            address = try? map.value("address")
            identifier = try map.value("identifier")
        }
    }

    struct QuoteRoute: ImmutableMappable {
        let expectedBuyAmount: Decimal?
        let approvalAddress: String?
        let tx: [String: Any]?
        let inboundAddress: String?
        let memo: String?
        let dustThreshold: Int?

        init(map: Map) throws {
            expectedBuyAmount = try? map.value("expectedBuyAmount", using: Transform.stringToDecimalTransform)
            approvalAddress = try? map.value("approvalAddress")
            tx = try? map.value("tx")
            inboundAddress = try? map.value("inboundAddress")
            memo = try? map.value("memo")
            dustThreshold = try? map.value("dustThreshold", using: Transform.stringToIntTransform)
        }
    }
}
