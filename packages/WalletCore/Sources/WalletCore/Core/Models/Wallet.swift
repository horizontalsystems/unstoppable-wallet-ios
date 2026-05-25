import MarketKit

public struct Wallet {
    public let token: Token
    public let account: Account

    public init(token: Token, account: Account) {
        self.token = token
        self.account = account
    }

    public var coin: Coin {
        token.coin
    }

    public var decimals: Int {
        token.decimals
    }

    public var transactionSource: TransactionSource {
        TransactionSource(
            blockchainType: token.blockchainType,
            meta: token.type.meta
        )
    }
}

extension Wallet: Identifiable {
    public var id: String {
        token.coin.uid + token.blockchainType.uid + token.type.id
    }
}

extension Wallet: Hashable {
    public static func == (lhs: Wallet, rhs: Wallet) -> Bool {
        lhs.token == rhs.token && lhs.account == rhs.account
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(token)
        hasher.combine(account)
    }
}
