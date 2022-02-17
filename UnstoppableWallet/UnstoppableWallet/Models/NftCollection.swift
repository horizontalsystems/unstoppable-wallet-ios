import ObjectMapper

struct NftCollection {
    let contracts: [Contract]
    let uid: String
    let name: String
    let description: String?
    let imageUrl: String?
    let featuredImageUrl: String?
    let externalUrl: String?
    let discordUrl: String?
    let twitterUsername: String?

    let averagePrice7d: NftPrice?
    let averagePrice30d: NftPrice?
    let totalSupply: Int

    struct Contract: ImmutableMappable {
        let address: String
        let schemaName: String

        init(address: String, schemaName: String) {
            self.address = address
            self.schemaName = schemaName
        }

        init(map: Map) throws {
            address = try map.value("address")
            schemaName = try map.value("schema_name")
        }

        func mapping(map: Map) {
            address >>> map["address"]
            schemaName >>> map["schema_name"]
        }
    }
}

struct NftAssetCollection {
    let collections: [NftCollection]
    let assets: [NftAsset]

    static var empty: NftAssetCollection {
        NftAssetCollection(collections: [], assets: [])
    }
}
