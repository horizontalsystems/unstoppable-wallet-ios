import MarketKit

struct ConfiguredPlatformCoin {
    let platformCoin: PlatformCoin
    let settings: CoinSettings

    init(platformCoin: PlatformCoin, settings: CoinSettings = [:]) {
        self.platformCoin = platformCoin
        self.settings = settings
    }
}

extension ConfiguredPlatformCoin: Hashable {

    public static func ==(lhs: ConfiguredPlatformCoin, rhs: ConfiguredPlatformCoin) -> Bool {
        lhs.platformCoin == rhs.platformCoin && lhs.settings == rhs.settings
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(platformCoin)
    }

}
