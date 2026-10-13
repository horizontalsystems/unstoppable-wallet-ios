import Alamofire
import Foundation
import ObjectMapper

// Split swap (/v3/split/*): one deposit of the sell asset delivered as several outputs. The calls
// mirror the simple v3 flow with the buy side pluralised; the deposit side (sell amount, fee, the
// transfer, the preview token) keeps its meaning.
extension USwapMultiSwapApi {
    func splitRate(_ request: SplitRequest) async throws -> SplitRateResult {
        let response: SplitRateResponseMapping = try await networkManager.fetch(
            url: endpoint("split/rate"),
            method: .post,
            parameters: request.parameters,
            encoding: JSONEncoding.default,
            headers: headers
        )

        return SplitRateResult(
            routes: response.routes.map(\.route),
            providerErrors: response.providerErrors.map(\.providerError)
        )
    }

    // No side effects: the split route with a `previewToken` and a `stubDepositAddress` for the fee
    // estimate. A split preview never carries an execution.
    func splitPreview(_ request: SplitRequest) async throws -> SplitRoute {
        let response: SplitRouteMapping = try await networkManager.fetch(
            url: endpoint("split/preview"),
            method: .post,
            parameters: request.parameters,
            encoding: JSONEncoding.default,
            headers: headers
        )

        return response.route
    }

    // Creates the split order. Failures follow `commit(_:)`: a non-2xx is rethrown as the raw network
    // error, a 2xx that is not `ok` or carries no `splitUuid` throws `CommitError` directly.
    func splitCommit(_ request: CommitRequest) async throws -> SplitCommitResponse {
        let response: SplitCommitResponseMapping = try await networkManager.fetch(
            url: endpoint("split/commit"),
            method: .post,
            parameters: ["previewToken": request.previewToken],
            encoding: JSONEncoding.default,
            headers: headers
        )

        let commit = response.response

        guard commit.status == "ok", let splitUuid = commit.splitUuid, !splitUuid.isEmpty else {
            throw CommitError(httpStatus: nil, status: commit.status, reason: nil, providerError: nil)
        }

        return commit
    }

    // Reports the inbound tx hash for every output of the split
    func splitSigned(splitUuid: String, inboundTxHash: String) async throws {
        let _: SplitSignedResponseMapping = try await networkManager.fetch(
            url: endpoint("split/signed"),
            method: .post,
            parameters: ["splitUuid": splitUuid, "inboundTxHash": inboundTxHash],
            encoding: JSONEncoding.default,
            headers: headers
        )
    }
}

extension USwapMultiSwapApi {
    // Body of /v3/split/rate (`providerIds`) and /v3/split/preview (`providerId`, addresses, fee).
    // Outputs are percent shares of the deposit, in request order.
    struct SplitRequest {
        let sellAsset: String
        let sellAmount: Decimal
        let slippage: Decimal
        let chainId: String?
        let outputs: [SplitRequestOutput]
        var providerIds: [String] = []
        var providerId: String?
        var sourceAddress: String?
        var refundAddress: String?
        var networkFee: NetworkFee?

        var parameters: Parameters {
            var parameters: Parameters = [
                "sellAsset": sellAsset,
                "sellAmount": sellAmount.description,
                "amountType": "percent",
                "slippage": slippage,
                "outputs": outputs.map(\.parameters),
            ]

            if !providerIds.isEmpty {
                parameters["providers"] = providerIds
            }
            if let providerId {
                parameters["provider"] = providerId
            }
            if let chainId {
                parameters["chainId"] = chainId
            }
            if let sourceAddress {
                parameters["sourceAddress"] = sourceAddress
            }
            if let refundAddress {
                parameters["refundAddress"] = refundAddress
            }
            if let networkFee {
                parameters["networkFee"] = networkFee.parameters
            }

            return parameters
        }
    }

    struct SplitRequestOutput {
        let buyAsset: String
        let percent: Int
        var destinationAddress: String?

        var parameters: Parameters {
            var parameters: Parameters = [
                "buyAsset": buyAsset,
                "amount": String(percent),
            ]

            if let destinationAddress {
                parameters["destinationAddress"] = destinationAddress
            }

            return parameters
        }
    }
}

public extension USwapMultiSwapApi {
    struct SplitRateResult {
        public let routes: [SplitRoute]
        public let providerErrors: [ProviderError]
    }

    struct SplitRoute {
        public let providerId: String
        // sorted by `index`, i.e. in request order
        public let outputs: [SplitRouteOutput]
        public let estimatedTime: TimeInterval?
        public let previewToken: String?
        public let stubDepositAddress: String?

        public var expectedBuyAmount: Decimal {
            outputs.map(\.expectedBuyAmount).reduce(0, +)
        }

        // The locked total of a fixed-rate split; nil when any output floats
        public var minBuyAmount: Decimal? {
            let mins = outputs.compactMap(\.minBuyAmount)
            return mins.count == outputs.count ? mins.reduce(0, +) : nil
        }
    }

    struct SplitRouteOutput {
        public let index: Int
        public let buyAsset: String
        public let destinationAddress: String?
        public let sellAmount: Decimal?
        public let expectedBuyAmount: Decimal
        public let minBuyAmount: Decimal?
    }

    struct SplitCommitResponse {
        public let status: String
        public let splitUuid: String?
        public let expiresAt: Date?
        public let execution: Execution?
        // sorted by `index`
        public let outputs: [SplitCommitOutput]
    }

    struct SplitCommitOutput {
        public let index: Int
        public let uuid: String
        public let destinationAddress: String?
        public let sellAmount: Decimal?
        public let expectedBuyAmount: Decimal?
        public let minBuyAmount: Decimal?
    }
}

extension USwapMultiSwapApi {
    struct SplitRateResponseMapping: ImmutableMappable {
        let routes: [SplitRouteMapping]
        let providerErrors: [ProviderErrorResponse]

        init(map: Map) throws {
            // A full refusal may omit routes (or send null) and carry only providerErrors
            routes = map.JSON["routes"] == nil || map.JSON["routes"] is NSNull ? [] : try map.value("routes")
            providerErrors = (try? map.value("providerErrors")) ?? []
        }
    }

    struct SplitRouteMapping: ImmutableMappable {
        let route: SplitRoute

        init(map: Map) throws {
            let outputs: [SplitRouteOutputMapping] = try map.value("outputs")

            route = SplitRoute(
                providerId: ((try? map.value("providers") as [String]) ?? []).first ?? "",
                outputs: outputs.map(\.output).sorted { $0.index < $1.index },
                estimatedTime: try? map.value("estimatedTime.total"),
                previewToken: try? map.value("previewToken"),
                stubDepositAddress: try? map.value("stubDepositAddress")
            )
        }
    }

    struct SplitRouteOutputMapping: ImmutableMappable {
        let output: SplitRouteOutput

        init(map: Map) throws {
            output = try SplitRouteOutput(
                index: map.value("index"),
                buyAsset: map.value("buyAsset"),
                destinationAddress: try? map.value("destinationAddress"),
                sellAmount: try? map.value("sellAmount", using: USwapMultiSwapApi.decimalTransform),
                expectedBuyAmount: map.value("expectedBuyAmount", using: USwapMultiSwapApi.decimalTransform),
                minBuyAmount: try? map.value("minBuyAmount", using: USwapMultiSwapApi.decimalTransform)
            )
        }
    }

    struct SplitCommitResponseMapping: ImmutableMappable {
        let response: SplitCommitResponse

        init(map: Map) throws {
            let status: String = try map.value("status")
            let outputs: [SplitCommitOutputMapping] = (try? map.value("outputs")) ?? []

            // Present must parse: a malformed execution that silently became nil would leave nothing to send
            let execution: ExecutionResponse? = map["execution"].currentValue != nil ? try map.value("execution") : nil

            response = SplitCommitResponse(
                status: status,
                splitUuid: try? map.value("splitUuid"),
                expiresAt: try? map.value("expiresAt", using: USwapMultiSwapApi.millisecondsDateTransform),
                execution: execution?.execution,
                outputs: outputs.map(\.output).sorted { $0.index < $1.index }
            )
        }
    }

    struct SplitCommitOutputMapping: ImmutableMappable {
        let output: SplitCommitOutput

        init(map: Map) throws {
            output = try SplitCommitOutput(
                index: map.value("index"),
                uuid: map.value("uuid"),
                destinationAddress: try? map.value("destinationAddress"),
                sellAmount: try? map.value("sellAmount", using: USwapMultiSwapApi.decimalTransform),
                expectedBuyAmount: try? map.value("expectedBuyAmount", using: USwapMultiSwapApi.decimalTransform),
                minBuyAmount: try? map.value("minBuyAmount", using: USwapMultiSwapApi.decimalTransform)
            )
        }
    }

    struct SplitSignedResponseMapping: ImmutableMappable {
        let splitUuid: String

        init(map: Map) throws {
            splitUuid = try map.value("splitUuid")
        }
    }
}
