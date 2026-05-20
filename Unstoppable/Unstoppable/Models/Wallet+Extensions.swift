import MarketKit
import WalletCore

extension Wallet {
    var badge: String? {
        token.badge
    }

    var transactionSource: TransactionSource {
        TransactionSource(
            blockchainType: token.blockchainType,
            meta: token.type.meta
        )
    }

    var priceCoinUid: String? {
        token.isCustom ? nil : coin.uid
    }
}
