import EvmKit
import Foundation
import MarketKit

public final class USwapCommitRequestBuilder {
    private struct DestinationCacheKey: Hashable {
        let accountId: String
        let blockchainType: BlockchainType
    }

    private let providerId: String
    private let shouldIncludeSourceAddress: (Token) -> Bool
    private var temporaryDestinationAddresses = [DestinationCacheKey: String]()

    public init(
        providerId: String,
        shouldIncludeSourceAddress: @escaping (Token) -> Bool = { token in
            token.blockchain.type.isEvm ||
                token.blockchainType == .tron ||
                token.blockchainType == .ton ||
                token.blockchainType == .solana
        }
    ) {
        self.providerId = providerId
        self.shouldIncludeSourceAddress = shouldIncludeSourceAddress
    }

    func build(
        sellAsset: String,
        buyAsset: String,
        sellAmount: Decimal,
        slippage: Decimal,
        tokenIn: Token,
        tokenOut: Token,
        recipient: String?,
        transactionSettings: TransactionSettings?
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
            refundAddress: refundAddress,
            networkFee: Self.networkFee(tokenIn: tokenIn, transactionSettings: transactionSettings)
        )
    }

    // The user's fee setting as the server expects it. The `kind` must match the sell chain (a mismatch
    // is a 400), so only the settings the server names are mapped: EVM gas price and the UTXO rate on
    // bitcoin / litecoin / bitcoinCash / dash (eCash is not in the server's list). Everything else —
    // account-abstraction, Monero, Zcash, bitcoin resend, Solana — sends nothing and the server prices
    // the transaction itself.
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
            case .bitcoin, .litecoin, .bitcoinCash, .dash:
                return .utxo(feeRate: satoshiPerByte)
            default:
                return nil
            }
        case .bitcoinResend, .monero, .aa, .zcash, .none:
            return nil
        }
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
        guard shouldIncludeSourceAddress(token) else {
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
