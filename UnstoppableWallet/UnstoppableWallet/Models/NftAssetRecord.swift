import Foundation
import GRDB
import MarketKit

class NftAssetRecord: Record {
    let blockchainTypeUid: String
    let accountId: String

    let nftUid: NftUid
    let providerCollectionUid: String
    let name: String?
    let previewImageUrl: String?
    let onSale: Bool
    let lastSalePrice: NftPriceRecord?

    init(blockchainTypeUid: String, accountId: String, asset: NftAssetShortMetadata) {
        self.blockchainTypeUid = blockchainTypeUid
        self.accountId = accountId
        nftUid = asset.nftUid
        providerCollectionUid = asset.providerCollectionUid
        name = asset.name
        previewImageUrl = asset.previewImageUrl
        onSale = asset.onSale
        lastSalePrice = asset.lastSalePrice.map { NftPriceRecord(price: $0) }

        super.init()
    }

    override class var databaseTableName: String {
        "nftAssetRecord"
    }

    enum Columns: String, ColumnExpression {
        case blockchainTypeUid
        case accountId
        case nftUid
        case providerCollectionUid
        case name
        case previewImageUrl
        case onSale
        case lastSalePriceTokenQueryId
        case lastSalePriceValue
    }

    required init(row: Row) {
        blockchainTypeUid = row[Columns.blockchainTypeUid]
        accountId = row[Columns.accountId]
        nftUid = row[Columns.nftUid]
        providerCollectionUid = row[Columns.providerCollectionUid]
        name = row[Columns.name]
        previewImageUrl = row[Columns.previewImageUrl]
        onSale = row[Columns.onSale]
        lastSalePrice = NftPriceRecord(tokenQueryId: row[Columns.lastSalePriceTokenQueryId], value: row[Columns.lastSalePriceValue])

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.blockchainTypeUid] = blockchainTypeUid
        container[Columns.accountId] = accountId
        container[Columns.nftUid] = nftUid
        container[Columns.providerCollectionUid] = providerCollectionUid
        container[Columns.name] = name
        container[Columns.previewImageUrl] = previewImageUrl
        container[Columns.onSale] = onSale
        container[Columns.lastSalePriceTokenQueryId] = lastSalePrice?.tokenQuery.id
        container[Columns.lastSalePriceValue] = lastSalePrice?.value
    }

}
