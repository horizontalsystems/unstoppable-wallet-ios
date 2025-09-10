import ObjectMapper

struct WhitelistDapp: ImmutableMappable, Equatable, Hashable {
    let name: String
    let url: String

    init(map: Map) throws {
        name = try map.value("name")
        url = try map.value("url")
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.name == rhs.name && lhs.url == rhs.url
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(url)
    }
}
