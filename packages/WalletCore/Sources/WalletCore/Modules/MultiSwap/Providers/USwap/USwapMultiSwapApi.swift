import Alamofire
import Foundation
import HsToolKit
import ObjectMapper

public final class USwapMultiSwapApi {
    // Amounts arrive as decimal strings on the amount fields but as bare JSON numbers on
    // providerErrors.minimumAmount/maximumAmount, so both representations are accepted.
    private static let decimalTransform = TransformOf<Decimal, Any>(
        fromJSON: { value in
            switch value {
            case let value as String: return Decimal(string: value)
            case let value as NSNumber: return Decimal(string: value.stringValue)
            default: return nil
            }
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

    public func providers() async throws -> [ProviderDescriptor] {
        let response: ProvidersResponse = try await networkManager.fetch(
            url: endpoint("providers"),
            headers: headers
        )

        return response.providers.map(\.descriptor)
    }

    public func rate(_ request: RateRequest) async throws -> RateResult {
        let response: RateResponse = try await networkManager.fetch(
            url: endpoint("rate"),
            method: .post,
            parameters: request.parameters,
            encoding: JSONEncoding.default,
            headers: headers
        )

        return RateResult(
            quotes: response.routes.map(\.quote),
            providerErrors: response.providerErrors.map(\.providerError)
        )
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
        public let ticker: String?

        public init(chain: String, chainId: String, address: String?, identifier: String, ticker: String? = nil) {
            self.chain = chain
            self.chainId = chainId
            self.address = address
            self.identifier = identifier
            self.ticker = ticker
        }
    }

    // /v2/rate and /v2/swap take exactly one of sellAmount / buyAmount — neither or both is a 400.
    enum AmountSpec: Equatable {
        case sell(Decimal)
        case buy(Decimal)

        public var value: Decimal {
            switch self {
            case let .sell(value), let .buy(value): return value
            }
        }

        public var isExactOutput: Bool {
            if case .buy = self { return true }
            return false
        }

        fileprivate var parameters: Parameters {
            switch self {
            case let .sell(value): return ["sellAmount": value.description]
            case let .buy(value): return ["buyAmount": value.description]
            }
        }
    }

    enum Privacy: String {
        case exclude
        case only
        case include
    }

    struct RateRequest {
        public let sellAsset: String
        public let buyAsset: String
        public let amount: AmountSpec
        public let slippage: Decimal
        public let chainId: String?
        public let providerIds: [String]
        public let privacy: Privacy

        public init(
            sellAsset: String,
            buyAsset: String,
            amount: AmountSpec,
            slippage: Decimal,
            chainId: String?,
            providerIds: [String],
            privacy: Privacy = .exclude
        ) {
            self.sellAsset = sellAsset
            self.buyAsset = buyAsset
            self.amount = amount
            self.slippage = slippage
            self.chainId = chainId
            self.providerIds = providerIds
            self.privacy = privacy
        }

        public init(
            sellAsset: String,
            buyAsset: String,
            sellAmount: Decimal,
            slippage: Decimal,
            chainId: String?,
            providerIds: [String],
            privacy: Privacy = .exclude
        ) {
            self.init(
                sellAsset: sellAsset,
                buyAsset: buyAsset,
                amount: .sell(sellAmount),
                slippage: slippage,
                chainId: chainId,
                providerIds: providerIds,
                privacy: privacy
            )
        }

        fileprivate var parameters: Parameters {
            var parameters: Parameters = [
                "sellAsset": sellAsset,
                "buyAsset": buyAsset,
                "slippage": slippage,
            ]

            parameters.merge(amount.parameters) { _, new in new }

            // An explicit provider list overrides the privacy filter server-side, so only one of
            // the two is ever sent.
            if providerIds.isEmpty {
                parameters["privacy"] = privacy.rawValue
            } else {
                parameters["providers"] = providerIds
            }

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
        public let providerId: String
        // In exact-output mode this is the answer: the amount to deposit, carrying the slippage
        // buffer over `minSellAmount`.
        public let sellAmount: Decimal?
        public let minSellAmount: Decimal?
        public let exactOutput: Bool

        public init(
            expectedBuyAmount: Decimal,
            minBuyAmount: Decimal?,
            buyAsset: String?,
            estimatedTime: TimeInterval?,
            approvalSpender: String?,
            providerId: String = "",
            sellAmount: Decimal? = nil,
            minSellAmount: Decimal? = nil,
            exactOutput: Bool = false
        ) {
            self.expectedBuyAmount = expectedBuyAmount
            self.minBuyAmount = minBuyAmount
            self.buyAsset = buyAsset
            self.estimatedTime = estimatedTime
            self.approvalSpender = approvalSpender
            self.providerId = providerId
            self.sellAmount = sellAmount
            self.minSellAmount = minSellAmount
            self.exactOutput = exactOutput
        }
    }

    struct ProviderError {
        // Tracking / diagnostics only — never shown in the UI.
        public let providerId: String
        public let message: String?
        public let errorCode: String?
        public let minimumAmount: Decimal?
        public let maximumAmount: Decimal?

        public init(providerId: String, message: String?, errorCode: String?, minimumAmount: Decimal?, maximumAmount: Decimal?) {
            self.providerId = providerId
            self.message = message
            self.errorCode = errorCode
            self.minimumAmount = minimumAmount
            self.maximumAmount = maximumAmount
        }
    }

    struct RateResult {
        public let quotes: [RateQuote]
        public let providerErrors: [ProviderError]

        public init(quotes: [RateQuote], providerErrors: [ProviderError]) {
            self.quotes = quotes
            self.providerErrors = providerErrors
        }
    }

    // A failed /v2/rate answers 200 with `{ routes, providerErrors }`; a failed /v2/swap answers a
    // non-2xx with the provider error *itself* as the body — `{ error, provider, errorCode?,
    // minimumAmount?, maximumAmount? }`, the same field set (API.txt §4, §9). Parsing it here keeps
    // both surfaces on one wire mapping, and hands the caller only structured fields, never the body.
    //
    // Explicitly internal despite the public extension: the only caller is PrivateSendService, in this
    // module — the same reason `track(_:)` is left internal in the class body above.
    internal static func providerError(networkError: Error) -> ProviderError? {
        guard let responseError = networkError as? NetworkManager.ResponseError,
              let json = responseError.json as? [String: Any],
              // Mapper.map(JSON:) is not throwing for any BaseMappable flavour — it reports failure as
              // nil — so there is nothing here to `try`.
              let response = Mapper<ProviderErrorResponse>().map(JSON: json)
        else {
            return nil
        }

        // A body with none of the provider-error markers is some other failure wearing the same
        // envelope (an auth rejection, a proxy page). Reporting nil lets the caller fall back on the
        // status code instead of inventing a route-level reason from it.
        guard response.errorCode != nil || response.minimumAmount != nil || response.maximumAmount != nil else {
            return nil
        }

        return response.providerError
    }

    struct ProviderDescriptor {
        public let id: String
        public let executionType: String
        public let confidential: Bool
        public let suspended: Bool
        public let amlPolicy: String?
        public let supportedChainIds: [String]

        public init(id: String, executionType: String, confidential: Bool, suspended: Bool, amlPolicy: String?, supportedChainIds: [String]) {
            self.id = id
            self.executionType = executionType
            self.confidential = confidential
            self.suspended = suspended
            self.amlPolicy = amlPolicy
            self.supportedChainIds = supportedChainIds
        }
    }

    struct SwapRequest {
        public let sellAsset: String
        public let buyAsset: String
        public let amount: AmountSpec
        public let slippage: Decimal
        public let chainId: String?
        public let providerId: String
        public let destinationAddress: String
        public let sourceAddress: String?
        public let refundAddress: String?

        public init(
            sellAsset: String,
            buyAsset: String,
            amount: AmountSpec,
            slippage: Decimal,
            chainId: String?,
            providerId: String,
            destinationAddress: String,
            sourceAddress: String?,
            refundAddress: String?
        ) {
            self.sellAsset = sellAsset
            self.buyAsset = buyAsset
            self.amount = amount
            self.slippage = slippage
            self.chainId = chainId
            self.providerId = providerId
            self.destinationAddress = destinationAddress
            self.sourceAddress = sourceAddress
            self.refundAddress = refundAddress
        }

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
            self.init(
                sellAsset: sellAsset,
                buyAsset: buyAsset,
                amount: .sell(sellAmount),
                slippage: slippage,
                chainId: chainId,
                providerId: providerId,
                destinationAddress: destinationAddress,
                sourceAddress: sourceAddress,
                refundAddress: refundAddress
            )
        }

        fileprivate var parameters: Parameters {
            var parameters: Parameters = [
                "sellAsset": sellAsset,
                "buyAsset": buyAsset,
                "slippage": slippage,
                "provider": providerId,
                "destinationAddress": destinationAddress,
            ]

            parameters.merge(amount.parameters) { _, new in new }

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
        public let sellAmount: Decimal?
        public let minSellAmount: Decimal?
        public let exactOutput: Bool

        public init(
            expectedBuyAmount: Decimal,
            minBuyAmount: Decimal?,
            buyAsset: String?,
            estimatedTime: TimeInterval?,
            execution: Execution?,
            uuid: String?,
            approvalSpender: String?,
            sellAmount: Decimal? = nil,
            minSellAmount: Decimal? = nil,
            exactOutput: Bool = false
        ) {
            self.expectedBuyAmount = expectedBuyAmount
            self.minBuyAmount = minBuyAmount
            self.buyAsset = buyAsset
            self.estimatedTime = estimatedTime
            self.execution = execution
            self.uuid = uuid
            self.approvalSpender = approvalSpender
            self.sellAmount = sellAmount
            self.minSellAmount = minSellAmount
            self.exactOutput = exactOutput
        }
    }

    enum Attachment: Equatable {
        case text(String)
        case destinationTag(String)
        case unknown(type: String, value: String)

        public var text: String? {
            if case let .text(value) = self { return value }
            return nil
        }

        init?(json: [String: Any]?) {
            guard let json, let type = json["type"] as? String else {
                return nil
            }

            let value = (json["value"] as? String) ?? (json["value"] as? NSNumber)?.stringValue ?? ""

            switch type {
            case "text": self = .text(value)
            case "destination_tag": self = .destinationTag(value)
            default: self = .unknown(type: type, value: value)
            }
        }

        // Only a text memo can be carried by the plain deposit transactions this app builds, and
        // only on a chain where that memo actually reaches the deposit-address owner. Anything else
        // must fail the route rather than be dropped: the provider matches the incoming deposit to
        // the order by this identifier, and a deposit it cannot match is typically unrecoverable.
        //
        // `memoType` is mandatory on purpose — it is what a caller must have decided BEFORE it can
        // read the memo out, so no new deposit builder can forget the question. Pass the chain's
        // BlockchainType.memoType, or the finer IPreSendHandler.memoType(address:) where the
        // destination address is known.
        public static func memo(_ attachment: Attachment?, memoType: MemoType) throws -> String? {
            switch attachment {
            case .none: return nil
            case let .some(.text(value)):
                guard memoType.deliversAttachment else { throw AttachmentError.undeliverable }
                return value
            case .some: throw AttachmentError.unsupported
            }
        }

        public enum AttachmentError: Error {
            // A destination tag or an attachment kind this app does not know how to carry.
            case unsupported
            // A text memo the transaction could technically hold, but which would never reach the
            // provider on this chain (local-only or encrypted on-chain).
            case undeliverable
        }
    }

    enum Execution {
        case signedTransaction(chain: String, transactions: [SignableTx], approval: Approval?)
        case transfer(chain: String, depositAddress: String, amount: Decimal?, attachment: Attachment?, unsignedTx: SignableTx?)
        case thorchainDeposit(chain: String, inboundAddress: String, memo: String, delivery: Delivery)
        case stellarBroker(StellarBrokerParams)

        var primarySignable: SignableTx? {
            switch self {
            case let .signedTransaction(_, transactions, _): transactions.first
            case let .transfer(_, _, _, _, unsignedTx): unsignedTx
            case let .thorchainDeposit(_, _, _, delivery): delivery.unsignedTx
            case .stellarBroker: nil
            }
        }

        public var depositAddress: String? {
            switch self {
            case .signedTransaction: nil
            case let .transfer(_, depositAddress, _, _, _): depositAddress
            case let .thorchainDeposit(_, inboundAddress, _, _): inboundAddress
            case .stellarBroker: nil
            }
        }

        // The amount the route wants deposited. Always transfer it as given — never recompute it.
        public var transferAmount: Decimal? {
            switch self {
            case .signedTransaction: return nil
            case let .transfer(_, _, amount, _, _): return amount
            case .thorchainDeposit: return nil
            case .stellarBroker: return nil
            }
        }

        public var chain: String? {
            switch self {
            case let .signedTransaction(chain, _, _): return chain
            case let .transfer(chain, _, _, _, _): return chain
            case let .thorchainDeposit(chain, _, _, _): return chain
            case .stellarBroker: return nil
            }
        }

        func depositInstruction() -> (address: String, amount: Decimal?, attachment: Attachment?)? {
            switch self {
            case let .transfer(_, depositAddress, amount, attachment, _):
                return (depositAddress, amount, attachment)
            case let .thorchainDeposit(_, inboundAddress, memo, _):
                return (inboundAddress, nil, .text(memo))
            case .signedTransaction, .stellarBroker:
                return nil
            }
        }
    }

    struct StellarBrokerParams {
        public let sellingAsset: String
        public let buyingAsset: String
        public let sellingAmount: String
        public let slippageTolerance: Double
        public let partnerKey: String?

        public init(
            sellingAsset: String,
            buyingAsset: String,
            sellingAmount: String,
            slippageTolerance: Double,
            partnerKey: String?
        ) {
            self.sellingAsset = sellingAsset
            self.buyingAsset = buyingAsset
            self.sellingAmount = sellingAmount
            self.slippageTolerance = slippageTolerance
            self.partnerKey = partnerKey
        }
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

extension USwapMultiSwapApi {
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
        let ticker: String?

        init(map: Map) throws {
            chain = try map.value("chain")
            chainId = try map.value("chainId")
            address = try? map.value("address")
            identifier = try map.value("identifier")
            ticker = try? map.value("ticker")
        }

        var token: Token {
            Token(
                chain: chain,
                chainId: chainId,
                address: address,
                identifier: identifier,
                ticker: ticker
            )
        }
    }

    struct CheckAddressesResponse: ImmutableMappable {
        let passedAmlCheck: Bool?

        init(map: Map) throws {
            passedAmlCheck = try? map.value("passedAmlCheck")
        }
    }

    struct ProvidersResponse: ImmutableMappable {
        let providers: [ProviderDescriptorResponse]

        init(map: Map) throws {
            providers = (try? map.value("providers")) ?? []
        }
    }

    struct ProviderDescriptorResponse: ImmutableMappable {
        let id: String
        let executionType: String
        let confidential: Bool
        let suspended: Bool
        let amlPolicy: String?
        let supportedChainIds: [String]

        init(map: Map) throws {
            id = try map.value("id")
            executionType = (try? map.value("executionType")) ?? ""
            confidential = (try? map.value("privacy.confidential")) ?? false
            suspended = (try? map.value("suspended")) ?? false
            amlPolicy = try? map.value("amlPolicy")
            supportedChainIds = (try? map.value("supportedChainIds")) ?? []
        }

        var descriptor: ProviderDescriptor {
            ProviderDescriptor(
                id: id,
                executionType: executionType,
                confidential: confidential,
                suspended: suspended,
                amlPolicy: amlPolicy,
                supportedChainIds: supportedChainIds
            )
        }
    }

    struct RateResponse: ImmutableMappable {
        let routes: [RateQuoteResponse]
        let providerErrors: [ProviderErrorResponse]

        init(map: Map) throws {
            routes = try map.value("routes")
            providerErrors = (try? map.value("providerErrors")) ?? []
        }
    }

    struct ProviderErrorResponse: ImmutableMappable {
        let providerId: String
        let message: String?
        let errorCode: String?
        let minimumAmount: Decimal?
        let maximumAmount: Decimal?

        init(map: Map) throws {
            providerId = ((try? map.value("provider")) ?? (try? map.value("providerId"))) ?? ""
            // The documented key is "error" on both surfaces (API.txt §3 line 187, §4 line 358);
            // "message" is accepted first because it is what some providers actually send.
            message = (try? map.value("message")) ?? (try? map.value("error"))
            errorCode = try? map.value("errorCode")
            minimumAmount = try? map.value("minimumAmount", using: USwapMultiSwapApi.decimalTransform)
            maximumAmount = try? map.value("maximumAmount", using: USwapMultiSwapApi.decimalTransform)
        }

        var providerError: ProviderError {
            ProviderError(
                providerId: providerId,
                message: message,
                errorCode: errorCode,
                minimumAmount: minimumAmount,
                maximumAmount: maximumAmount
            )
        }
    }

    struct RateQuoteResponse: ImmutableMappable {
        let expectedBuyAmount: Decimal
        let minBuyAmount: Decimal?
        let buyAsset: String?
        let estimatedTime: TimeInterval?
        let execution: ExecutionResponse?
        let approvalSpender: String?
        let providerId: String
        let sellAmount: Decimal?
        let minSellAmount: Decimal?
        let exactOutput: Bool

        init(map: Map) throws {
            expectedBuyAmount = try map.value("expectedBuyAmount", using: USwapMultiSwapApi.decimalTransform)
            minBuyAmount = try? map.value("minBuyAmount", using: USwapMultiSwapApi.decimalTransform)
            buyAsset = try? map.value("buyAsset")
            estimatedTime = try? map.value("estimatedTime.total")
            execution = try? map.value("execution")
            approvalSpender = (try? map.value("approvalSpender")) ?? execution?.approvalSpender
            providerId = ((try? map.value("providers") as [String]) ?? []).first ?? ""
            sellAmount = try? map.value("sellAmount", using: USwapMultiSwapApi.decimalTransform)
            minSellAmount = try? map.value("meta.near.minSellAmount", using: USwapMultiSwapApi.decimalTransform)
            exactOutput = (try? map.value("meta.near.exactOutput")) ?? false
        }

        var quote: RateQuote {
            RateQuote(
                expectedBuyAmount: expectedBuyAmount,
                minBuyAmount: minBuyAmount,
                buyAsset: buyAsset,
                estimatedTime: estimatedTime,
                approvalSpender: approvalSpender,
                providerId: providerId,
                sellAmount: sellAmount,
                minSellAmount: minSellAmount,
                exactOutput: exactOutput
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
        let sellAmount: Decimal?
        let minSellAmount: Decimal?
        let exactOutput: Bool

        init(map: Map) throws {
            expectedBuyAmount = try map.value("expectedBuyAmount", using: USwapMultiSwapApi.decimalTransform)
            minBuyAmount = try? map.value("minBuyAmount", using: USwapMultiSwapApi.decimalTransform)
            buyAsset = try? map.value("buyAsset")
            estimatedTime = try? map.value("estimatedTime.total")
            execution = try? map.value("execution")
            uuid = try? map.value("uuid")
            approvalSpender = (try? map.value("approvalSpender")) ?? execution?.approvalSpender
            sellAmount = try? map.value("sellAmount", using: USwapMultiSwapApi.decimalTransform)
            minSellAmount = try? map.value("meta.near.minSellAmount", using: USwapMultiSwapApi.decimalTransform)
            exactOutput = (try? map.value("meta.near.exactOutput")) ?? false
        }

        var response: SwapResponse {
            SwapResponse(
                expectedBuyAmount: expectedBuyAmount,
                minBuyAmount: minBuyAmount,
                buyAsset: buyAsset,
                estimatedTime: estimatedTime,
                execution: execution?.execution,
                uuid: uuid,
                approvalSpender: approvalSpender,
                sellAmount: sellAmount,
                minSellAmount: minSellAmount,
                exactOutput: exactOutput
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
        case transfer(chain: String, depositAddress: String, amount: Decimal?, attachment: Attachment?, unsignedTx: SignableTxResponse?)
        case thorchainDeposit(chain: String, inboundAddress: String, memo: String, delivery: DeliveryResponse)
        case stellarBroker(StellarBrokerParams)

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
                let attachmentJson: [String: Any]? = try? map.value("attachment")

                self = try .transfer(
                    chain: map.value("chain"),
                    depositAddress: map.value("depositAddress"),
                    amount: try? map.value("amount", using: USwapMultiSwapApi.decimalTransform),
                    attachment: Attachment(json: attachmentJson),
                    unsignedTx: try? map.value("unsignedTx")
                )
            case "thorchain_deposit":
                self = try .thorchainDeposit(
                    chain: map.value("chain"),
                    inboundAddress: map.value("inboundAddress"),
                    memo: map.value("memo"),
                    delivery: map.value("delivery")
                )
            case "stellar_broker":
                self = try .stellarBroker(
                    StellarBrokerParams(
                        sellingAsset: map.value("sellingAsset"),
                        buyingAsset: map.value("buyingAsset"),
                        sellingAmount: map.value("sellingAmount"),
                        slippageTolerance: map.value("slippageTolerance"),
                        partnerKey: try? map.value("partnerKey")
                    )
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
            case .stellarBroker:
                nil
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
            case let .transfer(chain, depositAddress, amount, attachment, unsignedTx):
                .transfer(
                    chain: chain,
                    depositAddress: depositAddress,
                    amount: amount,
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
            case let .stellarBroker(params):
                .stellarBroker(params)
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
            json = (try? map.value("json")) ?? map.JSON
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
