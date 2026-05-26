import Foundation
import MarketKit
import StellarKit
import TonKit
import WalletCore

extension AppValue {
    init(jetton: Jetton, value: Decimal) {
        self.init(kind: JettonAppValue(jetton: jetton), value: value)
    }

    init(asset: Asset, value: Decimal) {
        self.init(kind: StellarAppValue(asset: asset), value: value)
    }

    init(nftUid: NftUid, tokenName: String?, tokenSymbol: String?, value: Decimal) {
        self.init(kind: NftAppValue(nftUid: nftUid, tokenName: tokenName, tokenSymbol: tokenSymbol), value: value)
    }
}
