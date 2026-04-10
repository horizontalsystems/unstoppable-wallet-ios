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

extension SortCriterion {
    static let walletBalance: [SortCriterion] = [.nonZeroBalanceFirst, .hasPriceFirst, .fiatBalanceDescending, .balanceDescending]
    static let walletName: [SortCriterion] = [.nameAscending]
    static let walletPercentGrowth: [SortCriterion] = [.percentGrowthDescending]

    static let coinSelect: [SortCriterion] = [.balanceDescending, .enabled, .marketCapRank, .nameAscending]
    static let coinSelectFiltered: [SortCriterion] = [.balanceDescending, .enabled, .filterRelevance, .marketCapRank, .nameAscending]

    static let swapEnabled: [SortCriterion] = [.sameBlockchainFirst, .fiatBalanceDescending, .codeAscending, .codeNativeFirst, .blockchainOrder, .badge]
    static let swapSuggested: [SortCriterion] = [.marketCapRank, .codeNativeFirst, .blockchainOrder, .badge]
    static let swapFeatured: [SortCriterion] = [.codeNativeFirst, .blockchainOrder, .badge]

    static let tokenByBlockchain: [SortCriterion] = [.enabled, .codeNativeFirst, .blockchainOrder, .badge]
    static let tokenFilteredByBlockchain: [SortCriterion] = [.enabled, .filterRelevance, .codeNativeFirst, .blockchainOrder, .badge]

    static let transactionToken: [SortCriterion] = [.nameAscending, .codeNativeFirst, .badge]
    static let blockchainList: [SortCriterion] = [.tokenTypeOrder, .blockchainOrder]

    static let receiveCoin: [SortCriterion] = [.fiatBalanceDescending, .codeNativeFirst, .blockchainOrder, .nameAscending]
    static let receiveCoinFiltered: [SortCriterion] = [.codeNativeFirst]
}
