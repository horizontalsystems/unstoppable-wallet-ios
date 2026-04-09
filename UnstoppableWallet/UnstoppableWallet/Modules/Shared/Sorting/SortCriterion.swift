import Foundation

enum SortCriterion {
    // Ownership
    case enabled

    // Context-dependent
    case sameBlockchainFirst

    // Filter-based (require context.filter)
    case codeExact
    case codePrefix
    case nameExact
    case namePrefix

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
