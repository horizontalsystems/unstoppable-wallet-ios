import Foundation
import MarketKit
import StellarKit
import WalletCore

struct StellarAppValue: IAppValue {
    let asset: Asset

    var name: String { asset.code }
    var code: String { asset.code }
    var decimals: Int? { 7 }
    var tokenProtocol: TokenProtocol? { .stellar }

    func isSameKind(as other: any IAppValue) -> Bool {
        (other as? StellarAppValue).map { $0.asset == asset } ?? false
    }

    func isMaxValue(value: Decimal) -> Bool { value == StellarAdapter.maxValue }
}
