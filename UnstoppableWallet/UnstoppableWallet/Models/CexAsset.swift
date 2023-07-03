import Foundation
import MarketKit

struct CexAsset {
    static let decimals = 8

    let id: String
    let name: String
    let freeBalance: Decimal
    let lockedBalance: Decimal
    let depositEnabled: Bool
    let withdrawEnabled: Bool
    let networks: [CexNetwork]
    let coin: Coin?

    var coinCode: String {
        coin?.code ?? id
    }

    var coinName: String {
        coin?.name ?? name
    }

    var placeholderImageName: String {
        "_32"
    }

}

extension CexAsset: Hashable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func ==(lhs: CexAsset, rhs: CexAsset) -> Bool {
        lhs.id == rhs.id && lhs.freeBalance == rhs.freeBalance && lhs.lockedBalance == rhs.lockedBalance && lhs.networks == rhs.networks && lhs.coin == rhs.coin
    }

}
