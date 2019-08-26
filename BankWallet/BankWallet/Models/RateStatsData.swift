import ObjectMapper

struct RateStatsData: ImmutableMappable {
    var marketCap: Decimal?
    var stats: [String: ChartRateData]

    init(map: Map) throws {
        if let marketCapString: String = try map.value("market_cap") {
            marketCap = Decimal(string: marketCapString)
        }

        stats = try map.value("stats")
    }

}
