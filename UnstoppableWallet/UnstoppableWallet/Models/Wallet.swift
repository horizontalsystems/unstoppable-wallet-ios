import CoinKit

struct Wallet {
    let configuredCoin: ConfiguredCoin
    let account: Account

    init(configuredCoin: ConfiguredCoin, account: Account) {
        self.configuredCoin = configuredCoin
        self.account = account
    }

    init(coin: Coin, account: Account) {
        configuredCoin = ConfiguredCoin(coin: coin)
        self.account = account
    }

    var coin: Coin {
        configuredCoin.coin
    }

}

extension Wallet: Hashable {

    public static func ==(lhs: Wallet, rhs: Wallet) -> Bool {
        lhs.configuredCoin == rhs.configuredCoin && lhs.account == rhs.account
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(configuredCoin)
        hasher.combine(account)
    }

}
