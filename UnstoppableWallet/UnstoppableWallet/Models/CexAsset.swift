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
    let depositNetworks: [CexDepositNetwork]
    let withdrawNetworks: [CexWithdrawNetwork]
    let coin: Coin?

    var coinCode: String {
        coin?.code ?? id
    }

    var coinName: String {
        coin?.name ?? name
    }

}

extension CexAsset: Hashable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func ==(lhs: CexAsset, rhs: CexAsset) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name
                && lhs.freeBalance == rhs.freeBalance && lhs.lockedBalance == rhs.lockedBalance
                && lhs.depositEnabled == rhs.depositEnabled && lhs.withdrawEnabled == rhs.withdrawEnabled
                && lhs.depositNetworks == rhs.depositNetworks && lhs.withdrawNetworks == rhs.withdrawNetworks
                && lhs.coin == rhs.coin
    }

}
