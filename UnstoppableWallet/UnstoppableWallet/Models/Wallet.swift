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
                token: token,
                blockchainType: token.blockchainType,
                bep2Symbol: token.type.bep2Symbol
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
