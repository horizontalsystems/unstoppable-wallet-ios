import Foundation
import MarketKit

/// Builds the step list of a swap, as Swap Info shows it. Explorer URLs come from the injected closures,
/// so the steps can also be built without them (the activity list only needs the titles and statuses).
struct SwapLegsBuilder {
    typealias ChainExplorerUrl = (_ chainId: String, _ hash: String) -> String?
    typealias BlockchainExplorerUrl = (_ blockchainType: BlockchainType, _ hash: String) -> String?

    static var withoutUrls: SwapLegsBuilder {
        .init(chainExplorerUrl: nil, blockchainExplorerUrl: nil)
    }

    let chainExplorerUrl: ChainExplorerUrl?
    let blockchainExplorerUrl: BlockchainExplorerUrl?

    func legs(swap: Swap) -> [Leg] {
        // A split shows its recipients from the first poll on, before the track reports any asset or leg
        if swap.operation == .splitSwap, let outputs = swap.outputs, !outputs.isEmpty {
            return splitLegs(swap: swap, outputs: outputs)
        }

        guard let fromAsset = swap.fromAsset, let toAsset = swap.toAsset, let swapLegs = swap.legs else {
            if swap.status == .actionRequired {
                return actionRequiredLegs(swap: swap, existingLegs: [])
            } else {
                return []
            }
        }

        if swap.status == .actionRequired {
            return actionRequiredLegs(swap: swap, existingLegs: swapLegs)
        }

        return swapLegs.map { leg(swap: swap, leg: $0, fromAsset: fromAsset, toAsset: toAsset) }
    }

    /// One shared deposit step on top, from the split's top-level deposit leg, followed by each recipient's
    /// own steps, numbered by recipient. Rows stored by the former track shape carry a deposit leg per
    /// output, all flattened into `swap.legs`: they share the deposit hash and collapse into one step, and
    /// are left out of the outputs' own steps.
    private func splitLegs(swap: Swap, outputs: [Swap.Output]) -> [Leg] {
        let fromAsset = swap.fromAsset
        let toAsset = swap.toAsset
        let isDeposit: (Swap.Leg) -> Bool = {
            $0.type == USwapMultiSwapProvider.legTypeNativeSend && $0.outputIndex == nil && fromAsset != nil && $0.fromAsset == fromAsset
        }

        var depositGroups = [(txHash: String, legs: [Swap.Leg])]()
        for depositLeg in (swap.legs ?? []).filter(isDeposit) {
            if let index = depositGroups.firstIndex(where: { $0.txHash == depositLeg.txHash }) {
                depositGroups[index].legs.append(depositLeg)
            } else {
                depositGroups.append((txHash: depositLeg.txHash, legs: [depositLeg]))
            }
        }

        var depositLegs = depositGroups.compactMap { group -> Leg? in
            guard let first = group.legs.first else {
                return nil
            }

            return Leg(
                title: "swap_info.deposit".localized(swap.tokenIn.coin.code),
                status: group.legs.first(where: { $0.status != .completed })?.status ?? .completed,
                url: group.txHash.isEmpty ? nil : explorerUrl(chainId: first.chainId, hash: group.txHash)
            )
        }

        // Not observed yet: the deposit is on its way, or never arrived for a split that already ended
        if depositLegs.isEmpty {
            let status: Swap.Status = switch swap.status {
            case .notStarted, .completed, .failed, .refunded, .expired: swap.status
            case .signed, .pending, .swapping, .actionRequired, .unknown: .pending
            }

            depositLegs = [
                Leg(
                    title: "swap_info.deposit".localized(swap.tokenIn.coin.code),
                    status: status,
                    url: swap.txHash.flatMap { explorerUrl(blockchainType: swap.tokenIn.blockchainType, hash: $0) }
                ),
            ]
        }

        let outputLegs = outputs.flatMap { output -> [Leg] in
            let recipientNumber = output.index + 1
            let trackedLegs = output.legs.filter { !isDeposit($0) }

            // Every recipient shows a row from the first poll on, at its output's status until its payout is reported
            guard !trackedLegs.isEmpty else {
                return [
                    Leg(
                        title: "swap_info.receive".localized("\(swap.tokenOut.coin.code) \(recipientNumber)"),
                        status: output.status,
                        url: nil
                    ),
                ]
            }

            return trackedLegs.map { leg(swap: swap, leg: $0, fromAsset: fromAsset, toAsset: toAsset, recipientNumber: recipientNumber) }
        }

        return depositLegs + outputLegs
    }

    private func leg(swap: Swap, leg: Swap.Leg, fromAsset: String?, toAsset: String?, recipientNumber: Int? = nil) -> Leg {
        var title = "swap_info.unknown".localized

        if leg.refund {
            let code = recipientNumber.map { "\(swap.tokenIn.coin.code) \($0)" } ?? swap.tokenIn.coin.code
            title = "swap_info.refund".localized(code)
        } else if leg.type == USwapMultiSwapProvider.legTypeNativeSend {
            if leg.outputIndex == nil, leg.fromAsset == fromAsset {
                title = "swap_info.deposit".localized(swap.tokenIn.coin.code)
            } else if leg.outputIndex != nil || leg.toAsset == toAsset {
                // a split's payout leg is a receive even while the track leaves the shared `toAsset` empty
                let code = recipientNumber.map { "\(swap.tokenOut.coin.code) \($0)" } ?? swap.tokenOut.coin.code
                title = "swap_info.receive".localized(code)
            }
        } else if leg.type == USwapMultiSwapProvider.legTypeSwap {
            title = recipientNumber.map { "\("swap_info.swap".localized) \($0)" } ?? "swap_info.swap".localized
        }

        return Leg(
            title: title,
            status: leg.status,
            url: leg.txHash.isEmpty ? nil : explorerUrl(chainId: leg.chainId, hash: leg.txHash)
        )
    }

    private func actionRequiredLegs(swap: Swap, existingLegs: [Swap.Leg]) -> [Leg] {
        if isSingleChain(swap: swap) {
            return [
                Leg(
                    title: "swap_info.swap".localized,
                    status: .failed,
                    url: existingLegs.first.map { explorerUrl(chainId: $0.chainId, hash: $0.txHash) } ?? nil
                ),
            ]
        }

        let depositLeg = existingLegs.first { $0.type == USwapMultiSwapProvider.legTypeNativeSend && $0.fromAsset == swap.fromAsset }
        let swapLeg = existingLegs.first { $0.type == USwapMultiSwapProvider.legTypeSwap }

        return [
            Leg(
                title: "swap_info.deposit".localized(swap.tokenIn.coin.code),
                status: .completed,
                url: depositLeg.map { explorerUrl(chainId: $0.chainId, hash: $0.txHash) } ?? nil
            ),
            Leg(
                title: "swap_info.swap".localized,
                status: .failed,
                url: swapLeg.map { explorerUrl(chainId: $0.chainId, hash: $0.txHash) } ?? nil
            ),
        ]
    }

    private func isSingleChain(swap: Swap) -> Bool {
        swap.tokenIn.blockchainType == swap.tokenOut.blockchainType
    }

    private func explorerUrl(chainId: String, hash: String) -> String? {
        chainExplorerUrl?(chainId, hash) ?? nil
    }

    private func explorerUrl(blockchainType: BlockchainType, hash: String) -> String? {
        blockchainExplorerUrl?(blockchainType, hash) ?? nil
    }
}

extension SwapLegsBuilder {
    struct Leg: Hashable {
        let title: String
        let status: Swap.Status
        let url: String?

        /// Mirrors `SwapInfoView.legStatusIcon`: the spinner is shown for these two statuses
        var isInProgress: Bool {
            status == .pending || status == .swapping
        }

        var isDone: Bool {
            status == .completed || status == .refunded
        }
    }
}
