import MarketKit

struct ConfiguredPlatformCoin {
    let platformCoin: PlatformCoin
    let coinSettings: CoinSettings

    init(platformCoin: PlatformCoin, coinSettings: CoinSettings = [:]) {
        self.platformCoin = platformCoin
        self.coinSettings = coinSettings
    }
}

extension ConfiguredPlatformCoin: Hashable {

    public static func ==(lhs: ConfiguredPlatformCoin, rhs: ConfiguredPlatformCoin) -> Bool {
        lhs.platformCoin == rhs.platformCoin && lhs.coinSettings == rhs.coinSettings
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(platformCoin)
    }

}
