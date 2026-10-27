import Foundation

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
        // The v3 pre-observation body (`signed` / `not_started`) carries no assets, and a split sends `""`
        // (read as nil) while its outputs differ; keep the saved ones.
        if let fromAsset = response.fromAsset {
            swap.fromAsset = fromAsset
        }
        if let toAsset = response.toAsset {
            swap.toAsset = toAsset
        }
        swap.pauseReason = swap.status == .actionRequired ? response.pauseReason : nil
        swap.legs = response.legs.map(Self.leg)
        swap.outputs = Self.mergedOutputs(existing: swap.outputs, reported: response.outputs)

        if let amountOut = Self.completedAmountOut(status: swap.status, reportedToAmount: response.toAmount, outputs: swap.outputs) {
            swap.amountOut = amountOut
        }

        return swap
    }

    /// Merges a split's reported outputs into the stored ones by index. An output not observable on a given
    /// poll contributes no legs on that poll; keep showing what you last had for it. The stored entries
    /// are seeded at save time with every recipient's address and deposit share, which the report never
    /// replaces: the user-entered recipient stays the address shown, and an index outside the seeded
    /// set is not a recipient of this swap; a row saved without seeded outputs takes none from the report.
    /// Returns `existing` unchanged for a single swap (`reported == nil`).
    static func mergedOutputs(existing: [Swap.Output]?, reported: [USwapMultiSwapApi.TrackResponse.Output]?) -> [Swap.Output]? {
        guard let reported else {
            return existing
        }

        var outputs = existing ?? []

        for output in reported {
            guard let position = outputs.firstIndex(where: { $0.index == output.index }) else {
                continue
            }

            let previous = outputs[position]

            outputs[position] = Swap.Output(
                index: output.index,
                status: Swap.Status(rawValue: output.status) ?? .unknown,
                toAddress: previous.toAddress ?? output.toAddress,
                fromAmount: output.fromAmount ?? previous.fromAmount,
                toAmount: output.toAmount,
                legs: output.legs.map(Self.leg)
            )
        }

        return outputs.sorted { $0.index < $1.index }
    }

    /// The amount out to store for a completed swap: the server's top-level `toAmount` when it sends one.
    /// The server sends a split's total only once every output is paid, else `""`; when it is missing
    /// on a completed split, the merged (seeded) outputs' paid amounts add up to it, so an output the
    /// server reports outside the seeded set never counts.
    static func completedAmountOut(status: Swap.Status, reportedToAmount: Decimal?, outputs: [Swap.Output]?) -> Decimal? {
        guard status == .completed else {
            return nil
        }

        return reportedToAmount ?? outputsTotal(outputs: outputs)
    }

    private static func outputsTotal(outputs: [Swap.Output]?) -> Decimal? {
        guard let outputs, !outputs.isEmpty else {
            return nil
        }

        let amounts = outputs.compactMap(\.toAmount)
        return amounts.count == outputs.count ? amounts.reduce(0, +) : nil
    }

    private static func leg(_ leg: USwapMultiSwapApi.TrackResponse.Leg) -> Swap.Leg {
        Swap.Leg(
            status: Swap.Status(rawValue: leg.status) ?? .unknown,
            type: leg.type,
            chainId: leg.chainId,
            txHash: leg.txHash,
            fromAsset: leg.fromAsset,
            toAsset: leg.toAsset,
            toAddress: leg.toAddress,
            toAmount: leg.toAmount,
            outputIndex: leg.outputIndex,
            refund: leg.refund
        )
    }
}
