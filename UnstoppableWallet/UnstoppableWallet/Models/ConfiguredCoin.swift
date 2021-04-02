import CoinKit

struct ConfiguredCoin {
    let coin: Coin
    let settings: [CoinSetting: String]

    init(coin: Coin, settings: [CoinSetting: String] = [:]) {
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
        hasher.combine(settings)
    }

}
