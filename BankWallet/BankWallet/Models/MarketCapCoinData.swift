import ObjectMapper

struct MarketCapCoinData: ImmutableMappable {
    var supply: Int

    init(map: Map) throws {
        supply = Int(try map.value("circulating_supply") as String) ?? 0
    }

}
