import Foundation
import MarketKit

protocol ISendData {
    var feeData: FeeData? { get }
    var canSend: Bool { get }
    var rateCoins: [Coin] { get }
    var customSendButtonTitle: String? { get }
    func cautions(baseToken: Token) -> [CautionNew]
    func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection]
}

extension ISendData {
    var customSendButtonTitle: String? {
        nil
    }
}

struct SendDataSection {
    let fields: [SendField]
    let isList: Bool

    init(_ fields: [SendField], isList: Bool = true) {
        self.fields = fields
        self.isList = isList
    }
}
