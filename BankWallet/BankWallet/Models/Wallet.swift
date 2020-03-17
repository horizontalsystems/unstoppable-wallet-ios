struct Wallet {
    let coin: Coin
    let account: Account
}

extension Wallet: Hashable {

    public static func ==(lhs: Wallet, rhs: Wallet) -> Bool {
        lhs.coin == rhs.coin && lhs.account == rhs.account
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(coin)
        hasher.combine(account)
    }

}
