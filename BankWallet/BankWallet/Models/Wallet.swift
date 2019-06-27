struct Wallet {
    let coin: Coin
    let account: Account
}

extension Wallet: Equatable {

    public static func ==(lhs: Wallet, rhs: Wallet) -> Bool {
        return lhs.coin == rhs.coin && lhs.account == rhs.account
    }

}
