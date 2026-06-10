import Foundation

enum CoreDebugStubs {
    static func trackActionRequiredSwap(from swap: Swap) -> Swap {
        let fromAsset = swap.fromAsset ?? "\(swap.tokenIn.coin.code).\(swap.tokenIn.coin.code)"
        let toAsset = swap.toAsset ?? "\(swap.tokenOut.coin.code).\(swap.tokenOut.coin.code)"
        let inputChainId = USwapMultiSwapProvider.blockchainTypeMap.first { $0.value == swap.tokenIn.blockchainType }?.key ?? "1"
        let outputChainId = USwapMultiSwapProvider.blockchainTypeMap.first { $0.value == swap.tokenOut.blockchainType }?.key ?? "zcash"

        return Swap(
            uid: swap.uid,
            txHash: Constants.txHash,
            accountId: swap.accountId,
            providerId: Constants.providerId,
            status: .actionRequired,
            tokenIn: swap.tokenIn,
            tokenOut: swap.tokenOut,
            amountIn: swap.amountIn,
            amountOut: swap.amountOut,
            recipient: swap.recipient,
            toAddress: swap.toAddress,
            depositAddress: Constants.depositAddress,
            providerSwapId: swap.providerSwapId,
            sourceAddress: Constants.sourceAddress,
            refundAddress: Constants.sourceAddress,
            date: swap.date,
            fromAsset: fromAsset,
            toAsset: toAsset,
            legs: [
                .init(status: .actionRequired, type: USwapMultiSwapProvider.legTypeNativeSend, chainId: inputChainId, txHash: Constants.txHash, fromAsset: fromAsset, toAsset: fromAsset),
                .init(status: .actionRequired, type: USwapMultiSwapProvider.legTypeSwap, chainId: Constants.swapChainId, txHash: "", fromAsset: fromAsset, toAsset: toAsset),
                .init(status: .actionRequired, type: USwapMultiSwapProvider.legTypeNativeSend, chainId: outputChainId, txHash: "", fromAsset: toAsset, toAsset: toAsset),
            ],
            pauseReason: nil
        )
    }
}

private extension CoreDebugStubs {
    enum Constants {
        static let providerId = "NEAR"
        static let swapChainId = "near"
        static let txHash = "0x5c7f8414b7ffec480475b54be148bfccc8e9e50613a380ed84375ba3e0a2723d"
        static let sourceAddress = "0x3f4E9c3Ac73a4cff7540293c24a3D055E03fd78d"
        static let depositAddress = "0x5133504F5665C457036EB02CF4352830a3102D97"
    }
}
