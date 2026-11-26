import Foundation
import MarketKit

struct NearSendPayload: ChainSendPayload {
    let token: Token
    let amount: Decimal
    let address: String
    /// carried only by a NEP-141 ft_transfer; a NEAR transfer has no field for it
    let memo: String?
}

extension SendData {
    static func near(token: Token, amount: Decimal, address: String, memo: String?) -> SendData {
        .chain(NearSendPayload(token: token, amount: amount, address: address, memo: memo))
    }

    var nearPayload: NearSendPayload? {
        if case let .chain(payload) = self {
            return payload as? NearSendPayload
        }
        return nil
    }
}
