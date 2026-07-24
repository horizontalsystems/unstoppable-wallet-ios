import Foundation
import MarketKit

final class USwapCommitRequestBuilder {
    private struct DestinationCacheKey: Hashable {
        let accountId: String
        let blockchainType: BlockchainType
    }

    private let providerId: String
    private var temporaryDestinationAddresses = [DestinationCacheKey: String]()

    init(providerId: String) {
        self.providerId = providerId
    }

    func build(
        sellAsset: String,
        buyAsset: String,
        sellAmount: Decimal,
        slippage: Decimal,
        tokenIn: Token,
        tokenOut: Token,
        recipient: String?
    ) async throws -> USwapMultiSwapApi.SwapRequest {
        let destinationAddress = try await destinationAddress(recipient: recipient, token: tokenOut)
        let sourceAddress = try await sourceAddress(token: tokenIn)
        let refundAddress = try await refundAddress(token: tokenIn)

        return USwapMultiSwapApi.SwapRequest(
            sellAsset: sellAsset,
            buyAsset: buyAsset,
            sellAmount: sellAmount,
            slippage: slippage,
            chainId: chainId(token: tokenIn),
            providerId: providerId,
            destinationAddress: destinationAddress,
            sourceAddress: sourceAddress,
            refundAddress: refundAddress
        )
    }

    func destinationAddress(recipient: String?, token: Token) async throws -> String {
        if let recipient {
            return recipient
        }

        let cacheKey = Core.shared.accountManager.activeAccount.map {
            DestinationCacheKey(accountId: $0.id, blockchainType: token.blockchainType)
        }
        let temporary = cacheKey.flatMap { temporaryDestinationAddresses[$0] }
            .map { DestinationHelper.Destination(address: $0, type: .nonExisting) }
        let resolved = try await DestinationHelper.resolveDestination(token: token, temporary: temporary)

        if resolved.type == .nonExisting, let cacheKey {
            temporaryDestinationAddresses[cacheKey] = resolved.address
        }

        return resolved.address
    }

    func sourceAddress(token: Token) async throws -> String? {
        // `sourceAddress` tells USwap to build the executable transaction. The app consumes
        // that server-built execution only for EVM, Tron, TON, and Solana; other chains build
        // locally, so the field must stay absent for them.
        guard token.blockchain.type.isEvm ||
            token.blockchainType == .tron ||
            token.blockchainType == .ton ||
            token.blockchainType == .solana
        else {
            return nil
        }

        return try await DestinationHelper.resolveDestination(token: token).address
    }

    func refundAddress(token: Token) async throws -> String? {
        try await DestinationHelper.resolveDestination(token: token).address
    }

    func chainId(token: Token) -> String? {
        USwapAssetRepository.blockchainTypeMap.first(where: { $0.value == token.blockchainType })?.key
    }
}
