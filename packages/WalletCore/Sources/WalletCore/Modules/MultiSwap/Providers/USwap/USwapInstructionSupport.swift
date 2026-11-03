import Foundation
import MarketKit

/// Which `execution.method` each sell chain's final-quote builder can turn into a transaction. Mirrors
/// the builders: a method outside this table (or `.unsupported`) is refused by `USwapFinalQuoteFactory`
/// before any builder runs, so nothing is signed or sent from an instruction the app cannot follow.
enum USwapInstructionSupport {
    typealias Execution = USwapMultiSwapApi.Execution

    static func supports(method: String, blockchainType: BlockchainType) -> Bool {
        methods(blockchainType: blockchainType).contains(method)
    }

    static func methods(blockchainType: BlockchainType) -> Set<String> {
        switch blockchainType {
        case .ethereum, .binanceSmartChain, .polygon, .avalanche, .optimism, .arbitrumOne, .gnosis, .fantom, .base, .zkSync, .robinhood, .arc:
            // server-built tx, plain transfer, or the vault router call / direct vault deposit
            return [Execution.signedTransactionMethod, Execution.transferMethod, Execution.thorchainDepositMethod]
        case .bitcoin, .bitcoinCash, .ecash, .litecoin, .dash, .zcash:
            // plain transfer, or a vault deposit with the memo in OP_RETURN / a shielded memo output
            return [Execution.transferMethod, Execution.thorchainDepositMethod]
        case .tron, .ton, .solana, .stellar:
            return [Execution.signedTransactionMethod, Execution.transferMethod]
        case .monero, .zano, .xrp, .near:
            return [Execution.transferMethod]
        case .thorChain, .mayaChain:
            return [Execution.thorchainDepositMethod]
        case .unsupported:
            return []
        }
    }
}
