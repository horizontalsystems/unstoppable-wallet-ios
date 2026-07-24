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
        swap.fromAsset = response.fromAsset
        swap.toAsset = response.toAsset
        swap.pauseReason = swap.status == .actionRequired ? response.pauseReason : nil
        swap.legs = response.legs.map { leg in
            Swap.Leg(
                status: Swap.Status(rawValue: leg.status) ?? .unknown,
                type: leg.type,
                chainId: leg.chainId,
                txHash: leg.txHash,
                fromAsset: leg.fromAsset,
                toAsset: leg.toAsset
            )
        }

        if swap.status == .completed, let toAmount = response.toAmount {
            swap.amountOut = toAmount
        }

        return swap
    }
}
