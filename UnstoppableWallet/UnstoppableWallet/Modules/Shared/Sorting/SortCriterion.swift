import Foundation

enum SortCriterion {
    // Ownership
    case enabled

    // Context-dependent
    case sameBlockchainFirst
    case filterRelevance

    // Value
    case fiatBalanceDescending
    case balanceDescending
    case percentGrowthDescending

    // Metadata
    case marketCapRank
    case blockchainOrder
    case tokenTypeOrder
    case badge
    case codeAscending
    case codeNativeFirst
    case nameAscending

    // Wallet-specific
    case nonZeroBalanceFirst
    case hasPriceFirst
}
