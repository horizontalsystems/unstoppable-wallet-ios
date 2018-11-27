import ObjectMapper

struct LatestRate: ImmutableMappable {
    var value: Double
    var timestamp: Double

    init(map: Map) throws {
        value = try map.value("rate")
        timestamp = try map.value("date")
    }

    init(value: Double, timestamp: Double) {
        self.value = value
        self.timestamp = timestamp
    }

}
