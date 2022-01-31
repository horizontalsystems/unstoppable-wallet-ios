import Foundation

struct NftAssetOrder {
    let closingDate: Date
    let price: NftPrice?
    let emptyTaker: Bool
    let side: Int
    let v: Int?
    let ethValue: Decimal
}
