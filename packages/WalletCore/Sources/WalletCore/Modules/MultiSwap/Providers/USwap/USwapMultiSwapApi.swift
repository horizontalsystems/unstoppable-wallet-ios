import Alamofire
import Foundation
import HsToolKit
import ObjectMapper

public final class USwapMultiSwapApi {
    private static let decimalTransform = TransformOf<Decimal, String>(
        fromJSON: { value in
            guard let value else {
                return nil
            }
            return Decimal(string: value)
        },
        toJSON: { value in
            value?.description
        }
    )

    private let baseURL: URL
    private let headers: HTTPHeaders?
    private let networkManager: NetworkManager

    public init(baseURL: URL, apiKey: String?, networkManager: NetworkManager) {
        self.baseURL = baseURL
        self.networkManager = networkManager
        headers = apiKey.map { HTTPHeaders([HTTPHeader(name: "x-api-key", value: $0)]) }
    }

    public func tokens(providerId: String) async throws -> [Token] {
        let response: TokensResponse = try await networkManager.fetch(
            url: endpoint("tokens"),
            parameters: ["provider": providerId],
            headers: headers
        )

        return response.tokens.map(\.token)
    }

    public func checkAddresses(_ request: CheckAddressesRequest) async throws -> Bool? {
        let response: CheckAddressesResponse = try await networkManager.fetch(
            url: endpoint("check-addresses"),
            parameters: request.parameters,
            headers: headers
        )

        return response.passedAmlCheck
    }

    public func rate(_ request: RateRequest) async throws -> [RateQuote] {
        let response: RateResponse = try await networkManager.fetch(
            url: endpoint("rate"),
            method: .post,
            parameters: request.parameters,
            encoding: JSONEncoding.default,
            headers: headers
        )

        return response.routes.map(\.quote)
    }

    public func swap(_ request: SwapRequest) async throws -> SwapResponse {
        let response: SwapResponseMapping = try await networkManager.fetch(
            url: endpoint("swap"),
            method: .post,
            parameters: request.parameters,
            encoding: JSONEncoding.default,
            headers: headers
        )

        return response.response
    }

    func track(_ request: TrackRequest) async throws -> TrackResponse {
        let response: TrackResponseMapping = try await networkManager.fetch(
            url: endpoint(request.path),
            method: .post,
            parameters: request.parameters,
            encoding: JSONEncoding.default,
            headers: headers
        )

        return response.response
    }

    private func endpoint(_ path: String) -> String {
        baseURL.appendingPathComponent(path).absoluteString
    }
}

public extension USwapMultiSwapApi {
    struct CheckAddressesRequest {
        public let addresses: [String]

        public init(addresses: [String]) {
            self.addresses = addresses
        }

        fileprivate var parameters: Parameters {
            ["addresses": addresses.joined(separator: ",")]
        }
    }

    struct Token {
        public let chain: String
        public let chainId: String
        public let address: String?
        public let identifier: String

        public init(chain: String, chainId: String, address: String?, identifier: String) {
            self.chain = chain
            self.chainId = chainId
            self.address = address
            self.identifier = identifier
        }
    }

    struct RateRequest {
        public let sellAsset: String
        public let buyAsset: String
        public let sellAmount: Decimal
        public let slippage: Decimal
        public let chainId: String?
        public let providerIds: [String]

        public init(
            sellAsset: String,
            buyAsset: String,
            sellAmount: Decimal,
            slippage: Decimal,
            chainId: String?,
            providerIds: [String]
        ) {
            self.sellAsset = sellAsset
            self.buyAsset = buyAsset
            self.sellAmount = sellAmount
            self.slippage = slippage
            self.chainId = chainId
            self.providerIds = providerIds
        }

        fileprivate var parameters: Parameters {
            var parameters: Parameters = [
                "sellAsset": sellAsset,
                "buyAsset": buyAsset,
                "sellAmount": sellAmount.description,
                "slippage": slippage,
                "providers": providerIds,
            ]
            if let chainId {
                parameters["chainId"] = chainId
            }
            return parameters
        }
    }

    struct RateQuote {
        public let expectedBuyAmount: Decimal
        public let minBuyAmount: Decimal?
        public let buyAsset: String?
        public let estimatedTime: TimeInterval?
        public let approvalSpender: String?

        public init(
            expectedBuyAmount: Decimal,
            minBuyAmount: Decimal?,
            buyAsset: String?,
            estimatedTime: TimeInterval?,
            approvalSpender: String?
        ) {
            self.expectedBuyAmount = expectedBuyAmount
            self.minBuyAmount = minBuyAmount
            self.buyAsset = buyAsset
            self.estimatedTime = estimatedTime
            self.approvalSpender = approvalSpender
        }
    }

    struct SwapRequest {
        public let sellAsset: String
        public let buyAsset: String
        public let sellAmount: Decimal
        public let slippage: Decimal
        public let chainId: String?
        public let providerId: String
        public let destinationAddress: String
        public let sourceAddress: String?
        public let refundAddress: String?

        public init(
            sellAsset: String,
            buyAsset: String,
            sellAmount: Decimal,
            slippage: Decimal,
            chainId: String?,
            providerId: String,
            destinationAddress: String,
            sourceAddress: String?,
            refundAddress: String?
        ) {
            self.sellAsset = sellAsset
            self.buyAsset = buyAsset
            self.sellAmount = sellAmount
            self.slippage = slippage
            self.chainId = chainId
            self.providerId = providerId
            self.destinationAddress = destinationAddress
            self.sourceAddress = sourceAddress
            self.refundAddress = refundAddress
        }

        fileprivate var parameters: Parameters {
            var parameters: Parameters = [
                "sellAsset": sellAsset,
                "buyAsset": buyAsset,
                "sellAmount": sellAmount.description,
                "slippage": slippage,
                "provider": providerId,
                "destinationAddress": destinationAddress,
            ]
            if let chainId {
                parameters["chainId"] = chainId
            }
            if let sourceAddress {
                parameters["sourceAddress"] = sourceAddress
            }
            if let refundAddress {
                parameters["refundAddress"] = refundAddress
            }
            return parameters
        }
    }

    struct TrackRequest {
        public let path: String
        public let parameters: [String: Any]

        public init(path: String, parameters: [String: Any]) {
            self.path = path
            self.parameters = parameters
        }

        public static func swap(
            uuid: String?,
            inboundTxHash: String?
        ) -> Self {
            var parameters = [String: Any]()
            parameters.appendNotNil(key: "uuid", uuid)
            parameters.appendNotNil(key: "inboundTxHash", inboundTxHash)

            return .init(path: "track", parameters: parameters)
        }

        public static func evm(
            providerId: String,
            toAddress: String,
            transactionHash: String?,
            chainId: String?,
            fromAsset: String?,
            toAsset: String?,
            providerSwapId: String?
        ) -> Self {
            var parameters: [String: Any] = [
                "provider": providerId,
                "toAddress": toAddress,
            ]
            parameters.appendNotNil(key: "hash", transactionHash)
            parameters.appendNotNil(key: "chainId", chainId)
            parameters.appendNotNil(key: "fromAsset", fromAsset)
            parameters.appendNotNil(key: "toAsset", toAsset)
            parameters.appendNotNil(key: "providerSwapId", providerSwapId)

            return .init(path: "track/evm", parameters: parameters)
        }

        public static func thorchain(
            providerId: String,
            toAddress: String,
            inboundTxHash: String?,
            fromAsset: String?,
            toAsset: String?
        ) -> Self {
            var parameters: [String: Any] = [
                "provider": providerId,
                "toAddress": toAddress,
            ]
            parameters.appendNotNil(key: "inboundTxHash", inboundTxHash)
            parameters.appendNotNil(key: "fromAsset", fromAsset)
            parameters.appendNotNil(key: "toAsset", toAsset)

            return .init(path: "track/thorchain", parameters: parameters)
        }
    }

    struct SwapResponse {
        public let expectedBuyAmount: Decimal
        public let minBuyAmount: Decimal?
        public let buyAsset: String?
        public let estimatedTime: TimeInterval?
        public let execution: Execution?
        public let uuid: String?
        public let approvalSpender: String?

        public init(
            expectedBuyAmount: Decimal,
            minBuyAmount: Decimal?,
            buyAsset: String?,
            estimatedTime: TimeInterval?,
            execution: Execution?,
            uuid: String?,
            approvalSpender: String?
        ) {
            self.expectedBuyAmount = expectedBuyAmount
            self.minBuyAmount = minBuyAmount
            self.buyAsset = buyAsset
            self.estimatedTime = estimatedTime
            self.execution = execution
            self.uuid = uuid
            self.approvalSpender = approvalSpender
        }
    }

    enum Execution {
        case signedTransaction(chain: String, transactions: [SignableTx], approval: Approval?)
        case transfer(chain: String, depositAddress: String, attachment: [String: Any]?, unsignedTx: SignableTx?)
        case thorchainDeposit(chain: String, inboundAddress: String, memo: String, delivery: Delivery)
    }

    struct SignableTx {
        public let kind: String
        public let json: [String: Any]
        public let innerTx: Any?
        public let message: String?
        public let psbt: String?
        public let xdr: String?

        public init(kind: String, json: [String: Any], innerTx: Any?, message: String?, psbt: String?, xdr: String?) {
            self.kind = kind
            self.json = json
            self.innerTx = innerTx
            self.message = message
            self.psbt = psbt
            self.xdr = xdr
        }
    }

    struct Approval {
        public let spender: String

        public init(spender: String) {
            self.spender = spender
        }
    }

    struct Delivery {
        public let kind: String
        public let router: String?
        public let approval: Approval?
        public let shieldedMemoAddress: String?
        public let unsignedTx: SignableTx?

        public init(kind: String, router: String?, approval: Approval?, shieldedMemoAddress: String?, unsignedTx: SignableTx?) {
            self.kind = kind
            self.router = router
            self.approval = approval
            self.shieldedMemoAddress = shieldedMemoAddress
            self.unsignedTx = unsignedTx
        }
    }

    struct TrackResponse {
        public let status: String
        public let fromAsset: String
        public let toAsset: String
        public let toAmount: Decimal?
        public let legs: [Leg]
        public let provider: String?
        public let pauseReason: String?

        public init(
            status: String,
            fromAsset: String,
            toAsset: String,
            toAmount: Decimal?,
            legs: [Leg],
            provider: String?,
            pauseReason: String?
        ) {
            self.status = status
            self.fromAsset = fromAsset
            self.toAsset = toAsset
            self.toAmount = toAmount
            self.legs = legs
            self.provider = provider
            self.pauseReason = pauseReason
        }

        public struct Leg {
            public let status: String
            public let type: String
            public let chainId: String
            public let txHash: String
            public let fromAsset: String
            public let toAsset: String

            public init(
                status: String,
                type: String,
                chainId: String,
                txHash: String,
                fromAsset: String,
                toAsset: String
            ) {
                self.status = status
                self.type = type
                self.chainId = chainId
                self.txHash = txHash
                self.fromAsset = fromAsset
                self.toAsset = toAsset
            }
        }
    }
}

private extension USwapMultiSwapApi {
    struct TokensResponse: ImmutableMappable {
        let tokens: [TokenResponse]

        init(map: Map) throws {
            tokens = try map.value("tokens")
        }
    }

    struct TokenResponse: ImmutableMappable {
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

        var token: Token {
            Token(
                chain: chain,
                chainId: chainId,
                address: address,
                identifier: identifier
            )
        }
    }

    struct CheckAddressesResponse: ImmutableMappable {
        let passedAmlCheck: Bool?

        init(map: Map) throws {
            passedAmlCheck = try? map.value("passedAmlCheck")
        }
    }

    struct RateResponse: ImmutableMappable {
        let routes: [RateQuoteResponse]

        init(map: Map) throws {
            routes = try map.value("routes")
        }
    }

    struct RateQuoteResponse: ImmutableMappable {
        let expectedBuyAmount: Decimal
        let minBuyAmount: Decimal?
        let buyAsset: String?
        let estimatedTime: TimeInterval?
        let execution: ExecutionResponse?
        let approvalSpender: String?

        init(map: Map) throws {
            expectedBuyAmount = try map.value("expectedBuyAmount", using: USwapMultiSwapApi.decimalTransform)
            minBuyAmount = try? map.value("minBuyAmount", using: USwapMultiSwapApi.decimalTransform)
            buyAsset = try? map.value("buyAsset")
            estimatedTime = try? map.value("estimatedTime.total")
            execution = try? map.value("execution")
            approvalSpender = (try? map.value("approvalSpender")) ?? execution?.approvalSpender
        }

        var quote: RateQuote {
            RateQuote(
                expectedBuyAmount: expectedBuyAmount,
                minBuyAmount: minBuyAmount,
                buyAsset: buyAsset,
                estimatedTime: estimatedTime,
                approvalSpender: approvalSpender
            )
        }
    }

    struct SwapResponseMapping: ImmutableMappable {
        let expectedBuyAmount: Decimal
        let minBuyAmount: Decimal?
        let buyAsset: String?
        let estimatedTime: TimeInterval?
        let execution: ExecutionResponse?
        let uuid: String?
        let approvalSpender: String?

        init(map: Map) throws {
            expectedBuyAmount = try map.value("expectedBuyAmount", using: USwapMultiSwapApi.decimalTransform)
            minBuyAmount = try? map.value("minBuyAmount", using: USwapMultiSwapApi.decimalTransform)
            buyAsset = try? map.value("buyAsset")
            estimatedTime = try? map.value("estimatedTime.total")
            execution = try? map.value("execution")
            uuid = try? map.value("uuid")
            approvalSpender = (try? map.value("approvalSpender")) ?? execution?.approvalSpender
        }

        var response: SwapResponse {
            SwapResponse(
                expectedBuyAmount: expectedBuyAmount,
                minBuyAmount: minBuyAmount,
                buyAsset: buyAsset,
                estimatedTime: estimatedTime,
                execution: execution?.execution,
                uuid: uuid,
                approvalSpender: approvalSpender
            )
        }
    }

    struct TrackResponseMapping: ImmutableMappable {
        let status: String
        let fromAsset: String
        let toAsset: String
        let toAmount: Decimal?
        let legs: [LegMapping]
        let provider: String?
        let pauseReason: String?

        init(map: Map) throws {
            status = try map.value("status")
            fromAsset = try map.value("fromAsset")
            toAsset = try map.value("toAsset")
            toAmount = try? map.value("toAmount", using: USwapMultiSwapApi.decimalTransform)
            legs = try map.value("legs")
            provider = (try? map.value("providers") as [String])?.first
            pauseReason = try? map.value("meta.pauseReason")
        }

        var response: TrackResponse {
            TrackResponse(
                status: status,
                fromAsset: fromAsset,
                toAsset: toAsset,
                toAmount: toAmount,
                legs: legs.map(\.leg),
                provider: provider,
                pauseReason: pauseReason
            )
        }

        struct LegMapping: ImmutableMappable {
            let status: String
            let type: String
            let chainId: String
            let txHash: String
            let fromAsset: String
            let toAsset: String

            init(map: Map) throws {
                status = try map.value("status")
                type = try map.value("type")
                chainId = try map.value("chainId")
                txHash = (try? map.value("hash")) ?? ""
                fromAsset = try map.value("fromAsset")
                toAsset = try map.value("toAsset")
            }

            var leg: TrackResponse.Leg {
                TrackResponse.Leg(
                    status: status,
                    type: type,
                    chainId: chainId,
                    txHash: txHash,
                    fromAsset: fromAsset,
                    toAsset: toAsset
                )
            }
        }
    }

    enum ExecutionResponse: ImmutableMappable {
        case signedTransaction(chain: String, transactions: [SignableTxResponse], approval: ApprovalResponse?)
        case transfer(chain: String, depositAddress: String, attachment: [String: Any]?, unsignedTx: SignableTxResponse?)
        case thorchainDeposit(chain: String, inboundAddress: String, memo: String, delivery: DeliveryResponse)

        init(map: Map) throws {
            let method: String = try map.value("method")
            switch method {
            case "signed_transaction":
                self = try .signedTransaction(
                    chain: map.value("chain"),
                    transactions: (try? map.value("transactions")) ?? [],
                    approval: try? map.value("approval")
                )
            case "transfer":
                self = try .transfer(
                    chain: map.value("chain"),
                    depositAddress: map.value("depositAddress"),
                    attachment: try? map.value("attachment"),
                    unsignedTx: try? map.value("unsignedTx")
                )
            case "thorchain_deposit":
                self = try .thorchainDeposit(
                    chain: map.value("chain"),
                    inboundAddress: map.value("inboundAddress"),
                    memo: map.value("memo"),
                    delivery: map.value("delivery")
                )
            default:
                throw MapError(key: "method", currentValue: method, reason: "Unsupported execution method")
            }
        }

        var approvalSpender: String? {
            switch self {
            case let .signedTransaction(_, _, approval):
                approval?.spender
            case .transfer:
                nil
            case let .thorchainDeposit(_, _, _, delivery):
                delivery.approval?.spender
            }
        }

        var execution: Execution {
            switch self {
            case let .signedTransaction(chain, transactions, approval):
                .signedTransaction(
                    chain: chain,
                    transactions: transactions.map(\.signableTx),
                    approval: approval?.approval
                )
            case let .transfer(chain, depositAddress, attachment, unsignedTx):
                .transfer(
                    chain: chain,
                    depositAddress: depositAddress,
                    attachment: attachment,
                    unsignedTx: unsignedTx?.signableTx
                )
            case let .thorchainDeposit(chain, inboundAddress, memo, delivery):
                .thorchainDeposit(
                    chain: chain,
                    inboundAddress: inboundAddress,
                    memo: memo,
                    delivery: delivery.delivery
                )
            }
        }
    }

    struct SignableTxResponse: ImmutableMappable {
        let kind: String
        let json: [String: Any]
        let innerTx: Any?
        let message: String?
        let psbt: String?
        let xdr: String?

        init(map: Map) throws {
            kind = try map.value("kind")
            json = map.JSON
            innerTx = try? map.value("tx")
            message = try? map.value("message")
            psbt = try? map.value("psbt")
            xdr = try? map.value("xdr")
        }

        var signableTx: SignableTx {
            SignableTx(
                kind: kind,
                json: json,
                innerTx: innerTx,
                message: message,
                psbt: psbt,
                xdr: xdr
            )
        }
    }

    struct ApprovalResponse: ImmutableMappable {
        let spender: String

        init(map: Map) throws {
            spender = try map.value("spender")
        }

        var approval: Approval {
            Approval(spender: spender)
        }
    }

    struct DeliveryResponse: ImmutableMappable {
        let kind: String
        let router: String?
        let approval: ApprovalResponse?
        let shieldedMemoAddress: String?
        let unsignedTx: SignableTxResponse?

        init(map: Map) throws {
            kind = try map.value("kind")
            router = try? map.value("router")
            approval = try? map.value("approval")
            shieldedMemoAddress = try? map.value("shieldedMemoAddress")
            unsignedTx = try? map.value("unsignedTx")
        }

        var delivery: Delivery {
            Delivery(
                kind: kind,
                router: router,
                approval: approval?.approval,
                shieldedMemoAddress: shieldedMemoAddress,
                unsignedTx: unsignedTx?.signableTx
            )
        }
    }
}
