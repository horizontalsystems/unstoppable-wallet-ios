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

    func flowSection(baseToken _: Token, currency _: Currency, rates _: [String: Decimal]) -> (SendField, SendField)? {
        nil
    }
}

class SendDataSection {
    let fields: [SendField]
    let isFlow: Bool
    let isList: Bool

    init(_ fields: [SendField], isFlow: Bool = false, isList: Bool = true) {
        self.fields = fields
        self.isFlow = isFlow
        self.isList = isList
    }
}
