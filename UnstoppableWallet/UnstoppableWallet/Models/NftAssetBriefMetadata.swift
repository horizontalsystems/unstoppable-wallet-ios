import GRDB

class NftAssetBriefMetadata: Record {
    let nftUid: NftUid
    let providerCollectionUid: String?
    let name: String?
    let imageUrl: String?
    let previewImageUrl: String?

    init(nftUid: NftUid, providerCollectionUid: String? = nil, name: String? = nil, imageUrl: String? = nil, previewImageUrl: String? = nil) {
        self.nftUid = nftUid
        self.providerCollectionUid = providerCollectionUid
        self.name = name
        self.imageUrl = imageUrl
        self.previewImageUrl = previewImageUrl

        super.init()
    }

    override class var databaseTableName: String {
        "nftAssetBriefMetadata"
    }

    enum Columns: String, ColumnExpression {
        case nftUid
        case providerCollectionUid
        case name
        case imageUrl
        case previewImageUrl
    }

    required init(row: Row) {
        nftUid = row[Columns.nftUid]
        providerCollectionUid = row[Columns.providerCollectionUid]
        name = row[Columns.name]
        imageUrl = row[Columns.imageUrl]
        previewImageUrl = row[Columns.previewImageUrl]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.nftUid] = nftUid
        container[Columns.providerCollectionUid] = providerCollectionUid
        container[Columns.name] = name
        container[Columns.imageUrl] = imageUrl
        container[Columns.previewImageUrl] = previewImageUrl
    }

}
