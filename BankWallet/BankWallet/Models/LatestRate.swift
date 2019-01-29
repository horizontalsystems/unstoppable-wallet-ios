import ObjectMapper

struct LatestRate: ImmutableMappable {
    var value: Decimal
    var timestamp: Double

    init(map: Map) throws {
        value = try map.value("rate_str", nested: false, delimiter: ".", using: TransformOf<Decimal, String>(fromJSON: { return $0 == nil ? nil : Decimal(string: $0!) }, toJSON: { _ in  nil }))
        timestamp = try map.value("date")
    }

    init(value: Decimal, timestamp: Double) {
        self.value = value
        self.timestamp = timestamp
    }

}
