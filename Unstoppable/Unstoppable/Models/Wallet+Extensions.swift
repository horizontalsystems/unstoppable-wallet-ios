import MarketKit
import WalletCore

extension Wallet {
    var badge: String? {
        token.badge
    }

    var priceCoinUid: String? {
        token.isCustom ? nil : coin.uid
    }

    var transactionSource: TransactionSource {
        TransactionSource(
            blockchainType: token.blockchainType,
            meta: token.type.meta
        )
    }
}
