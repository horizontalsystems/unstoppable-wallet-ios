import ObjectMapper

struct LatestRateData: ImmutableMappable {
    var values: [String: Decimal]
    var timestamp: Double

    init(map: Map) throws {
        values = try map.value("rates", using: TransformOf<[String: Decimal], [String: String]>(fromJSON: { strings -> [String: Decimal]? in
            guard let strings = strings else {
                return nil
            }

            var result = [String: Decimal]()

            for (key, value) in strings {
                if let decimal = Decimal(string: value) {
                    result[key] = decimal
                }
            }

            return result
        }, toJSON: { _ in nil }))

        timestamp = try map.value("time")
    }

}
