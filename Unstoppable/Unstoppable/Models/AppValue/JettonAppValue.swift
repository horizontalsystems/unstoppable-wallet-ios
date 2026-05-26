import Foundation
import MarketKit
import TonKit
import WalletCore

struct JettonAppValue: IAppValue {
    let jetton: Jetton

    var name: String { jetton.name }
    var code: String { jetton.symbol }
    var decimals: Int? { jetton.decimals }
    var tokenProtocol: TokenProtocol? { .jetton }

    func isSameKind(as other: any IAppValue) -> Bool {
        (other as? JettonAppValue).map { $0.jetton == jetton } ?? false
    }
}
