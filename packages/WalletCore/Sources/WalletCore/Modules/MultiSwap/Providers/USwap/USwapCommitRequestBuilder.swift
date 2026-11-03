import EvmKit
import Foundation
import MarketKit

/// Builds the `/v3/preview` body: the addresses the route needs, resolved from the account, with the
/// Zcash ones following the route's `addressRules` (`USwapZcashAddressPolicy`).
public final class USwapCommitRequestBuilder {
    private struct DestinationCacheKey: Hashable {
        let accountId: String
        let blockchainType: BlockchainType
        let shielded: Bool
    }

    private let shouldIncludeSourceAddress: (Token) -> Bool
    private let cacheLock = NSLock()
    private var temporaryDestinationAddresses = [DestinationCacheKey: String]()

    public init(
        shouldIncludeSourceAddress: @escaping (Token) -> Bool = { token in
            token.blockchain.type.isEvm ||
                token.blockchainType == .tron ||
                token.blockchainType == .ton ||
                token.blockchainType == .solana ||
                token.blockchainType == .zcash ||
                token.blockchainType == .stellar
        }
    ) {
        self.shouldIncludeSourceAddress = shouldIncludeSourceAddress
    }

    /// `destinationKind` is resolved by the caller (the route's rule plus the OP_RETURN memo guard) so the
    /// same kind drives the recipient check, the recipient parser filter and this request.
    func build(
        venueId: String,
        addressRules: USwapMultiSwapApi.ZcashAddressRules?,
        destinationKind: ZcashAddressKind,
        sellAsset: String,
        buyAsset: String,
        sellAmount: Decimal,
        slippage: Decimal,
        tokenIn: Token,
        tokenOut: Token,
        recipient: String?,
        transactionSettings: TransactionSettings?
    ) async throws -> USwapMultiSwapApi.SwapRequest {
        let destinationAddress = try await destinationAddress(
            recipient: recipient,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            kind: destinationKind
        )
        let refundAddress = try await refundAddress(token: tokenIn, kind: USwapZcashAddressPolicy.refundKind(rules: addressRules))
        let sourceAddress = try await sourceAddress(
            token: tokenIn,
            policy: USwapZcashAddressPolicy.sourcePolicy(rules: addressRules),
            refundAddress: refundAddress
        )

        return USwapMultiSwapApi.SwapRequest(
            sellAsset: sellAsset,
            buyAsset: buyAsset,
            sellAmount: sellAmount,
            slippage: slippage,
            chainId: chainId(token: tokenIn),
            providerId: venueId,
            destinationAddress: destinationAddress,
            sourceAddress: sourceAddress,
            refundAddress: refundAddress,
            networkFee: Self.networkFee(tokenIn: tokenIn, transactionSettings: transactionSettings)
        )
    }

    /// The user's fee setting as the server expects it. The `kind` must match the sell chain (a mismatch
    /// is a 400), so only the settings the server names are mapped: EVM gas price and the UTXO rate on
    /// bitcoin / litecoin / bitcoinCash / dash / zcash (eCash is not in the server's list). Everything
    /// else — account-abstraction, Monero, bitcoin resend, Solana — sends nothing and the server prices
    /// the transaction itself.
    static func networkFee(tokenIn: Token, transactionSettings: TransactionSettings?) -> USwapMultiSwapApi.NetworkFee? {
        switch transactionSettings {
        case let .evm(gasPriceData, _):
            guard tokenIn.blockchainType.isEvm else {
                return nil
            }

            switch gasPriceData.userDefined {
            case let .legacy(gasPrice):
                return .legacy(gasPrice: String(gasPrice))
            case let .eip1559(maxFeePerGas, maxPriorityFeePerGas):
                return .eip1559(maxFeePerGas: String(maxFeePerGas), maxPriorityFeePerGas: String(maxPriorityFeePerGas))
            }
        case let .bitcoin(satoshiPerByte):
            switch tokenIn.blockchainType {
            case .bitcoin, .litecoin, .bitcoinCash, .dash, .zcash:
                return .utxo(feeRate: satoshiPerByte)
            default:
                return nil
            }
        case .bitcoinResend, .monero, .aa, .zcash, .none:
            return nil
        }
    }

    /// The buy-side address: the typed recipient, else the account's own. A ZEC output follows the route's
    /// destination rule: the unified address built from its receivers, or the transparent one. A generated
    /// address (no wallet for the buy token yet) is cached per account, chain and kind so every re-preview
    /// of one operation names the same address.
    func destinationAddress(recipient: String?, tokenIn _: Token, tokenOut: Token, kind: ZcashAddressKind) async throws -> String {
        if let recipient {
            return recipient
        }

        let shielded = tokenOut.blockchainType == .zcash && kind != .transparent

        let cacheKey = Core.shared.accountManager.activeAccount.map {
            DestinationCacheKey(accountId: $0.id, blockchainType: tokenOut.blockchainType, shielded: shielded)
        }
        let temporary = cacheKey.flatMap { key in cacheLock.withLock { temporaryDestinationAddresses[key] } }
            .map { DestinationHelper.Destination(address: $0, type: .nonExisting) }
        let resolved = if shielded {
            try await DestinationHelper.resolveDestinationUnified(
                token: tokenOut,
                receivers: USwapZcashAddressPolicy.receiversToBuild(kind: kind),
                temporary: temporary
            )
        } else {
            try await DestinationHelper.resolveDestination(token: tokenOut, temporary: temporary)
        }

        if resolved.type == .nonExisting, let cacheKey {
            cacheLock.withLock { temporaryDestinationAddresses[cacheKey] = resolved.address }
        }

        return resolved.address
    }

    /// The sender named to the provider. On a ZEC sell it follows the route's `source` rule: omitted
    /// without one (a transfer venue builds nothing from it), the refund address under `sameAsRefund`
    /// (the provider refunds to the sender), or an address of the rule's own kind.
    func sourceAddress(token: Token, policy: ZcashSourcePolicy, refundAddress: String?) async throws -> String? {
        if token.blockchainType == .zcash {
            switch policy {
            case .omit:
                return nil
            case .sameAsRefund:
                return refundAddress
            case let .own(kind):
                return try await zcashAddress(token: token, kind: kind)
            }
        }

        guard shouldIncludeSourceAddress(token) else {
            return nil
        }

        return try await DestinationHelper.resolveDestination(token: token).address
    }

    /// Where a failed swap is refunded: the account's own address, following the route's `refund` rule on ZEC.
    func refundAddress(token: Token, kind: ZcashAddressKind) async throws -> String? {
        if token.blockchainType == .zcash {
            return try await zcashAddress(token: token, kind: kind)
        }

        return try await DestinationHelper.resolveDestination(token: token).address
    }

    private func zcashAddress(token: Token, kind: ZcashAddressKind) async throws -> String {
        switch kind {
        case .transparent:
            return try await DestinationHelper.resolveDestination(token: token).address
        case .unified:
            return try await DestinationHelper.unifiedAddress(token: token, receivers: USwapZcashAddressPolicy.receiversToBuild(kind: kind))
        }
    }

    func chainId(token: Token) -> String? {
        USwapAssetMapping.chainId(blockchainType: token.blockchainType)
    }
}
