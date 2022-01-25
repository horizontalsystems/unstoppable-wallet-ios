struct NftCollection {
    let slug: String
    let name: String
    let imageUrl: String?
    let floorPrice: NftPrice?
    let assets: [NftAsset]
}
