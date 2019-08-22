import ObjectMapper

struct MarketCapData: ImmutableMappable {
    var timestamp: TimeInterval
    var coins: [String: MarketCapCoinData]

    init(map: Map) throws {
        timestamp = try map.value("timestamp")
        coins = try map.value("coins")
    }

}
