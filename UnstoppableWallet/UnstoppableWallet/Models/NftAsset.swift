import ObjectMapper

struct NftAsset {
    let contract: NftCollection.Contract
    let collectionUid: String
    let tokenId: String
    let name: String?
    let imageUrl: String?
    let imagePreviewUrl: String?
    let description: String?
    let externalLink: String?
    let permalink: String?
    let traits: [Trait]
    let lastSalePrice: NftPrice?
    let onSale: Bool

    struct Trait: ImmutableMappable {
        let type: String
        let value: String
        let count: Int

        init(type: String, value: String, count: Int) {
            self.type = type
            self.value = value
            self.count = count
        }

        init(map: Map) throws {
            type = try map.value("type")
            value = try map.value("value")
            count = try map.value("count")
        }

        func mapping(map: Map) {
            type >>> map["type"]
            value >>> map["value"]
            count >>> map["count"]
        }
    }
}
