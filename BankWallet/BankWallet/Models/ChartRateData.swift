import ObjectMapper

struct ChartRateData: ImmutableMappable {
    var values: [Decimal]
    var timestamp: TimeInterval
    var scale: TimeInterval

    init(map: Map) throws {
        timestamp = try map.value("timestamp")
        scale = try map.value("scale_minutes")

        values = try map.value("rates", using: TransformOf<[Decimal], [String]>(fromJSON: { strings -> [Decimal]? in
            guard let strings = strings else {
                return nil
            }

            let result: [Decimal] = strings.compactMap { Decimal(string: $0) }

            return result
        }, toJSON: { _ in nil }))
    }

}
