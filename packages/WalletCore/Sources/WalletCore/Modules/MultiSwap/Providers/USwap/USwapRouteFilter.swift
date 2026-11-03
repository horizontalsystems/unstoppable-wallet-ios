import Foundation
import MarketKit

/// Drops the `/v3/rate` routes this app cannot execute, judged from the venue's `executionType` (a rate
/// route carries no `execution` yet): a vault deposit (`thorchain_deposit`) sold from a chain whose
/// deposit cannot carry the route memo, and `stellar_broker` routes (an interactive WebSocket session
/// this app does not run). An unknown execution type is kept; the preview decides.
enum USwapRouteFilter {
    static let vaultExecutionType = "thorchain_deposit"
    static let stellarBrokerExecutionType = "stellar_broker"

    static func filter(
        _ routes: [USwapMultiSwapApi.RateQuote],
        tokenIn: Token,
        executionType: (String) -> String?
    ) -> [USwapMultiSwapApi.RateQuote] {
        routes.filter { isExecutable(executionType: executionType($0.providerId), tokenIn: tokenIn) }
    }

    static func isExecutable(executionType: String?, tokenIn: Token) -> Bool {
        switch executionType {
        case stellarBrokerExecutionType:
            return false
        case vaultExecutionType:
            return supportsVaultDeposit(blockchainType: tokenIn.blockchainType)
        default:
            return true
        }
    }

    /// A vault deposit needs the swap memo to reach the vault. The app can carry it on chains whose
    /// memo is public on-chain (UTXO OP_RETURN, THORChain / Maya memo), inside a server-built EVM
    /// transaction (calldata / router call), or through a vault's shielded memo address on Zcash.
    /// Solana, Tron and XRP deposits built here carry no text memo, so they are not offered as a sell
    /// side even when the server quotes them.
    static func supportsVaultDeposit(blockchainType: BlockchainType) -> Bool {
        blockchainType.isEvm || blockchainType == .zcash || blockchainType.memoType == .onChainPublic
    }
}
