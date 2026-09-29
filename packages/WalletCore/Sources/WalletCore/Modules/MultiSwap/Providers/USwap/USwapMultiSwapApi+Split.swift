import Alamofire
import Foundation
import ObjectMapper

// Split swap: one sell asset swapped into one buy asset and delivered to several addresses.
// Request / response shapes mirror the Swapuz split-order API (POST /api/split-order/rate,
// POST /api/split-order), with USwap asset ids in place of Swapuz coin / network pairs.
extension USwapMultiSwapApi {
    private static let stubRateFactor = Decimal(99) / 100

    // TODO: integrate backend split-order endpoints (reference: Swapuz POST /api/split-order/rate, POST /api/split-order)
    // `stubRate` only feeds the stub; remove it at integration.
    func splitRate(_ request: SplitRateRequest, stubRate: Decimal) async throws -> SplitRateResponse {
        try await Task.sleep(nanoseconds: 600_000_000)
        try Task.checkCancellation()

        let outputs = request.outputs.map { output in
            SplitRateResultOutput(
                buyAsset: output.buyAsset,
                amount: output.amount,
                amountResult: request.depositAmount * output.amount / 100 * stubRate * Self.stubRateFactor
            )
        }

        let total = outputs.map(\.amountResult).reduce(0, +)

        return SplitRateResponse(
            amount: request.depositAmount,
            outputs: outputs,
            minAmount: nil,
            maxAmount: nil,
            guaranteedAmount: total * Self.stubRateFactor,
            estimatedTime: 900
        )
    }

    // TODO: integrate backend split-order endpoints (reference: Swapuz POST /api/split-order/rate, POST /api/split-order)
    // The stub returns an EMPTY deposit address, so the confirmation fails until the backend is integrated.
    func createSplitOrder(_ request: CreateSplitOrderRequest) async throws -> SplitOrderResponse {
        try await Task.sleep(nanoseconds: 600_000_000)
        try Task.checkCancellation()

        return SplitOrderResponse(
            publicUid: UUID().uuidString,
            status: "Remaining",
            depositAmount: request.depositAmount,
            depositAddress: "",
            depositMemo: nil,
            expiresAt: nil
        )
    }
}

extension USwapMultiSwapApi {
    enum SplitAmountType: String {
        case absolute = "Absolute"
        case percent = "Percent"
    }

    struct SplitRateRequest {
        let sellAsset: String
        let depositAmount: Decimal
        let amountType: SplitAmountType
        let chainId: String?
        let providerIds: [String]
        let outputs: [SplitRateOutput]

        var parameters: Parameters {
            var parameters: Parameters = [
                "sellAsset": sellAsset,
                "depositAmount": depositAmount.description,
                "amountType": amountType.rawValue,
                "providers": providerIds,
                "outputs": outputs.map(\.parameters),
            ]

            if let chainId {
                parameters["chainId"] = chainId
            }

            return parameters
        }
    }

    struct SplitRateOutput {
        let buyAsset: String
        let amount: Decimal

        var parameters: Parameters {
            [
                "buyAsset": buyAsset,
                "amount": amount.description,
            ]
        }
    }

    struct CreateSplitOrderRequest {
        let sellAsset: String
        let depositAmount: Decimal
        let amountType: SplitAmountType
        let providerIds: [String]
        let refundAddress: String?
        let refundMemo: String?
        let outputs: [SplitOrderOutput]

        var parameters: Parameters {
            var parameters: Parameters = [
                "sellAsset": sellAsset,
                "depositAmount": depositAmount.description,
                "amountType": amountType.rawValue,
                "providers": providerIds,
                "outputs": outputs.map(\.parameters),
            ]

            if let refundAddress {
                parameters["refundAddress"] = refundAddress
            }

            if let refundMemo {
                parameters["refundMemo"] = refundMemo
            }

            return parameters
        }
    }

    struct SplitOrderOutput {
        let buyAsset: String
        let address: String
        let memo: String?
        let amount: Decimal

        var parameters: Parameters {
            var parameters: Parameters = [
                "buyAsset": buyAsset,
                "address": address,
                "amount": amount.description,
            ]

            if let memo {
                parameters["memo"] = memo
            }

            return parameters
        }
    }

    public struct SplitRateResponse {
        public let amount: Decimal
        public let outputs: [SplitRateResultOutput]
        public let minAmount: Decimal?
        public let maxAmount: Decimal?
        public let guaranteedAmount: Decimal?
        public let estimatedTime: TimeInterval?
    }

    public struct SplitRateResultOutput {
        public let buyAsset: String
        public let amount: Decimal
        public let amountResult: Decimal
    }

    public struct SplitOrderResponse {
        public let publicUid: String
        public let status: String
        public let depositAmount: Decimal
        public let depositAddress: String
        public let depositMemo: String?
        public let expiresAt: Date?
    }
}

// Response mappings for the backend integration; unused by the stubs above.
extension USwapMultiSwapApi {
    struct SplitRateResponseMapping: ImmutableMappable {
        let response: SplitRateResponse

        init(map: Map) throws {
            let outputs: [SplitRateResultOutputMapping] = try map.value("outputs")

            response = try SplitRateResponse(
                amount: map.value("amount", using: USwapMultiSwapApi.decimalTransform),
                outputs: outputs.map(\.output),
                minAmount: try? map.value("minAmount", using: USwapMultiSwapApi.decimalTransform),
                maxAmount: try? map.value("maxAmount", using: USwapMultiSwapApi.decimalTransform),
                guaranteedAmount: try? map.value("guaranteedAmount", using: USwapMultiSwapApi.decimalTransform),
                estimatedTime: try? map.value("estimatedTime")
            )
        }
    }

    struct SplitRateResultOutputMapping: ImmutableMappable {
        let output: SplitRateResultOutput

        init(map: Map) throws {
            output = try SplitRateResultOutput(
                buyAsset: map.value("buyAsset"),
                amount: map.value("amount", using: USwapMultiSwapApi.decimalTransform),
                amountResult: map.value("amountResult", using: USwapMultiSwapApi.decimalTransform)
            )
        }
    }

    struct SplitOrderResponseMapping: ImmutableMappable {
        let response: SplitOrderResponse

        init(map: Map) throws {
            response = try SplitOrderResponse(
                publicUid: map.value("publicUid"),
                status: map.value("status"),
                depositAmount: map.value("depositAmount", using: USwapMultiSwapApi.decimalTransform),
                depositAddress: map.value("depositAddress"),
                depositMemo: try? map.value("depositMemo"),
                expiresAt: try? map.value("expiresAt", using: ISO8601DateTransform())
            )
        }
    }
}
