public final class USwapTracker {
    private let api: USwapMultiSwapApi
    private let shouldSimulateFailure: () -> Bool

    public init(api: USwapMultiSwapApi, shouldSimulateFailure: @escaping () -> Bool) {
        self.api = api
        self.shouldSimulateFailure = shouldSimulateFailure
    }

    public func track(
        swap: Swap,
        request: USwapMultiSwapApi.TrackRequest
    ) async throws -> Swap {
        var parameters = request.parameters
        if shouldSimulateFailure() {
            parameters["testActionRequired"] = true
        }
        parameters.merge(SwapTrackParametersFactory.extraParameters(swap: swap)) { current, _ in current }

        let response = try await api.track(
            .init(path: request.path, parameters: parameters)
        )

        var swap = swap
        swap.status = Swap.Status(rawValue: response.status) ?? .unknown
        // The v3 pre-observation body (`signed` / `not_started`) carries no assets; keep the saved ones.
        if let fromAsset = response.fromAsset {
            swap.fromAsset = fromAsset
        }
        if let toAsset = response.toAsset {
            swap.toAsset = toAsset
        }
        swap.pauseReason = swap.status == .actionRequired ? response.pauseReason : nil
        swap.legs = response.legs.map(Self.leg)
        if let outputs = response.outputs {
            swap.outputs = outputs.map { output in
                Swap.Output(
                    index: output.index,
                    status: Swap.Status(rawValue: output.status) ?? .unknown,
                    toAddress: output.toAddress,
                    fromAmount: output.fromAmount,
                    toAmount: output.toAmount,
                    legs: output.legs.map(Self.leg)
                )
            }
        }

        if swap.status == .completed, let toAmount = response.toAmount {
            swap.amountOut = toAmount
        }

        return swap
    }

    private static func leg(_ leg: USwapMultiSwapApi.TrackResponse.Leg) -> Swap.Leg {
        Swap.Leg(
            status: Swap.Status(rawValue: leg.status) ?? .unknown,
            type: leg.type,
            chainId: leg.chainId,
            txHash: leg.txHash,
            fromAsset: leg.fromAsset,
            toAsset: leg.toAsset
        )
    }
}
