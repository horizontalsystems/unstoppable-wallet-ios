import CoinKit

struct ConfiguredCoin {
    let coin: Coin
    let settings: CoinSettings

    init(coin: Coin, settings: CoinSettings = [:]) {
        self.coin = coin
        self.settings = settings
    }
}

extension ConfiguredCoin: Hashable {

    public static func ==(lhs: ConfiguredCoin, rhs: ConfiguredCoin) -> Bool {
        lhs.coin == rhs.coin && lhs.settings == rhs.settings
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(coin)
    }

}
