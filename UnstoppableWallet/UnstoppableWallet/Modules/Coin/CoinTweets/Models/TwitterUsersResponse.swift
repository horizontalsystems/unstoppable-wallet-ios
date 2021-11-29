import ObjectMapper

struct TwitterUsersResponse: ImmutableMappable {
    let users: [TwitterUser]

    init(map: Map) throws {
        users = try map.value("data")
    }

}

struct TwitterUser: ImmutableMappable {
    let id: String
    let name: String
    let username: String
    let profileImageUrl: String

    init(map: Map) throws {
        id = try map.value("id")
        name = try map.value("name")
        username = try map.value("username")
        profileImageUrl = try map.value("profile_image_url")
    }
}
