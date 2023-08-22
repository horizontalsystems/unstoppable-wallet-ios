import MarketKit

struct Wallet {
    let token: Token
    let account: Account

    init(token: Token, account: Account) {
        self.token = token
        self.account = account
    }

    var coin: Coin {
        token.coin
    }

    var decimals: Int {
        token.decimals
    }

    var badge: String? {
        token.badge
    }

    var transactionSource: TransactionSource {
        TransactionSource(
                blockchainType: token.blockchainType,
                meta: token.type.meta
        )
    }

}

extension Wallet: Hashable {

    public static func ==(lhs: Wallet, rhs: Wallet) -> Bool {
        lhs.token == rhs.token && lhs.account == rhs.account
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(token)
        hasher.combine(account)
    }

}
