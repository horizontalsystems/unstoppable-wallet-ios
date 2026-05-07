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
    // Wallet Screen & Send-List Screen. Sort-options

    static let walletBalance: [SortCriterion] = [.nonZeroBalanceFirst, .hasPriceFirst, .fiatBalanceDescending, .balanceDescending]
    static let walletName: [SortCriterion] = [.nameAscending]
    static let walletPercentGrowth: [SortCriterion] = [.percentGrowthDescending]

    // Legacy code
    static let coinSelect: [SortCriterion] = [.balanceDescending, .enabled, .marketCapRank, .nameAscending]
    static let coinSelectFiltered: [SortCriterion] = [.balanceDescending, .enabled, .filterRelevance, .marketCapRank, .nameAscending]

    // MultiSwap coin selection
    static let swapEnabled: [SortCriterion] = [.sameBlockchainFirst, .fiatBalanceDescending, .codeAscending, .codeNativeFirst, .blockchainOrder, .badge]
    static let swapSuggested: [SortCriterion] = [.marketCapRank, .codeNativeFirst, .blockchainOrder, .badge]
    static let swapFeatured: [SortCriterion] = [.codeNativeFirst, .blockchainOrder, .badge]

    // MultiSwap filtered by evm-address and text
    static let tokenByBlockchain: [SortCriterion] = [.enabled, .codeNativeFirst, .blockchainOrder, .badge]
    static let tokenFilteredByBlockchain: [SortCriterion] = [.enabled, .filterRelevance, .codeNativeFirst, .blockchainOrder, .badge]

    // Legacy Transactions Screen
    static let transactionToken: [SortCriterion] = [.nameAscending, .codeNativeFirst, .badge]

    // Receive-Blockchains Screen
    static let blockchainList: [SortCriterion] = [.tokenTypeOrder, .blockchainOrder]

    // Receive-List Screen
    static let receiveCoin: [SortCriterion] = [.fiatBalanceDescending, .codeNativeFirst, .blockchainOrder, .nameAscending]
    static let receiveCoinFiltered: [SortCriterion] = [.codeNativeFirst]
}
